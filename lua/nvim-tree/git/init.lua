local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local git_utils = require "nvim-tree.git.utils"
local Runner = require "nvim-tree.git.runner"
local Watcher = require("nvim-tree.watcher").Watcher
local Iterator = require "nvim-tree.iterators.node-iterator"
local explorer_node = require "nvim-tree.explorer.node"

local M = {
  config = {},

  -- all projects keyed by toplevel
  _projects_by_toplevel = {},

  -- index of paths inside toplevels, false when not inside a project
  _toplevels_by_path = {},

  -- git dirs by toplevel
  _git_dirs_by_toplevel = {},
}

-- Files under .git that should result in a reload when changed.
-- Utilities (like watchman) can also write to this directory (often) and aren't useful for us.
local WATCHED_FILES = {
  "FETCH_HEAD", -- remote ref
  "HEAD", -- local ref
  "HEAD.lock", -- HEAD will not always be updated e.g. revert
  "config", -- user config
  "index", -- staging area
}

---@param toplevel string|nil
---@param path string|nil
---@param project table
---@param git_status table|nil
local function reload_git_status(toplevel, path, project, git_status)
  if path then
    for p in pairs(project.files) do
      if p:find(path, 1, true) == 1 then
        project.files[p] = nil
      end
    end
    project.files = vim.tbl_deep_extend("force", project.files, git_status)
  else
    project.files = git_status
  end

  project.dirs = git_utils.file_status_to_dir_status(project.files, toplevel)
end

--- Is this path in a known ignored directory?
---@param path string
---@param project table git status
---@return boolean
local function path_ignored_in_project(path, project)
  if not path or not project then
    return false
  end

  if project and project.files then
    for file, status in pairs(project.files) do
      if status == "!!" and vim.startswith(path, file) then
        return true
      end
    end
  end
  return false
end

--- Reload all projects
---@return table projects maybe empty
function M.reload()
  if not M.config.git.enable then
    return {}
  end

  for toplevel in pairs(M._projects_by_toplevel) do
    M.reload_project(toplevel)
  end

  return M._projects_by_toplevel
end

--- Reload one project. Does nothing when no project or path is ignored
---@param toplevel string|nil
---@param path string|nil optional path to update only
---@param callback function|nil
function M.reload_project(toplevel, path, callback)
  local project = M._projects_by_toplevel[toplevel]
  if not toplevel or not project or not M.config.git.enable then
    if callback then
      callback()
    end
    return
  end

  if path and (path:find(toplevel, 1, true) ~= 1 or path_ignored_in_project(path, project)) then
    if callback then
      callback()
    end
    return
  end

  local opts = {
    toplevel = toplevel,
    path = path,
    list_untracked = git_utils.should_show_untracked(toplevel),
    list_ignored = true,
    timeout = M.config.git.timeout,
  }

  if callback then
    Runner.run(opts, function(git_status)
      reload_git_status(toplevel, path, project, git_status)
      callback()
    end)
  else
    -- TODO use callback once async/await is available
    local git_status = Runner.run(opts)
    reload_git_status(toplevel, path, project, git_status)
  end
end

--- Retrieve a known project
---@param toplevel string|nil
---@return table|nil project
function M.get_project(toplevel)
  return M._projects_by_toplevel[toplevel]
end

--- Retrieve the toplevel for a path. nil on:
---  git disabled
---  not part of a project
---  not a directory
---  path in git.disable_for_dirs
---@param path string absolute
---@return string|nil
function M.get_toplevel(path)
  if not M.config.git.enable then
    return nil
  end

  if M._toplevels_by_path[path] then
    return M._toplevels_by_path[path]
  end

  if M._toplevels_by_path[path] == false then
    return nil
  end

  local stat, _ = vim.loop.fs_stat(path)
  if not stat or stat.type ~= "directory" then
    return nil
  end

  -- short-circuit any known ignored paths
  for root, project in pairs(M._projects_by_toplevel) do
    if project and path_ignored_in_project(path, project) then
      M._toplevels_by_path[path] = root
      return root
    end
  end

  -- attempt to fetch toplevel
  local toplevel, git_dir = git_utils.get_toplevel(path)
  if not toplevel or not git_dir then
    return nil
  end

  -- ignore disabled paths
  for _, disabled_for_dir in ipairs(M.config.git.disable_for_dirs) do
    local toplevel_norm = vim.fn.fnamemodify(toplevel, ":p")
    local disabled_norm = vim.fn.fnamemodify(disabled_for_dir, ":p")
    if toplevel_norm == disabled_norm then
      return nil
    end
  end

  M._toplevels_by_path[path] = toplevel
  M._git_dirs_by_toplevel[toplevel] = git_dir
  return M._toplevels_by_path[path]
end

local function reload_tree_at(toplevel)
  if not M.config.git.enable or not toplevel then
    return nil
  end

  log.line("watcher", "git event executing '%s'", toplevel)
  local root_node = utils.get_node_from_path(toplevel)
  if not root_node then
    return
  end

  M.reload_project(toplevel, nil, function()
    local git_status = M.get_project(toplevel)

    Iterator.builder(root_node.nodes)
      :hidden()
      :applier(function(node)
        local parent_ignored = explorer_node.is_git_ignored(node.parent)
        explorer_node.update_git_status(node, parent_ignored, git_status)
      end)
      :recursor(function(node)
        return node.nodes and #node.nodes > 0 and node.nodes
      end)
      :iterate()

    require("nvim-tree.renderer").draw()
  end)
end

--- Load the project status for a path. Does nothing when no toplevel for path.
--- Only fetches project status when unknown, otherwise returns existing.
---@param path string absolute
---@return table project maybe empty
function M.load_project_status(path)
  if not M.config.git.enable then
    return {}
  end

  local toplevel = M.get_toplevel(path)
  if not toplevel then
    M._toplevels_by_path[path] = false
    return {}
  end

  local status = M._projects_by_toplevel[toplevel]
  if status then
    return status
  end

  local git_status = Runner.run {
    toplevel = toplevel,
    list_untracked = git_utils.should_show_untracked(toplevel),
    list_ignored = true,
    timeout = M.config.git.timeout,
  }

  local watcher = nil
  if M.config.filesystem_watchers.enable then
    log.line("watcher", "git start")

    local callback = function(w)
      log.line("watcher", "git event scheduled '%s'", w.toplevel)
      utils.debounce("git:watcher:" .. w.toplevel, M.config.filesystem_watchers.debounce_delay, function()
        if w.destroyed then
          return
        end
        reload_tree_at(w.toplevel)
      end)
    end

    local git_dir = vim.env.GIT_DIR or M._git_dirs_by_toplevel[toplevel] or utils.path_join { toplevel, ".git" }
    watcher = Watcher:new(git_dir, WATCHED_FILES, callback, {
      toplevel = toplevel,
    })
  end

  if git_status then
    M._projects_by_toplevel[toplevel] = {
      files = git_status,
      dirs = git_utils.file_status_to_dir_status(git_status, toplevel),
      watcher = watcher,
    }
    return M._projects_by_toplevel[toplevel]
  else
    M._toplevels_by_path[path] = false
    return {}
  end
end

function M.purge_state()
  log.line("git", "purge_state")

  for _, project in pairs(M._projects_by_toplevel) do
    if project.watcher then
      project.watcher:destroy()
    end
  end

  M._projects_by_toplevel = {}
  M._toplevels_by_path = {}
  M._git_dirs_by_toplevel = {}
end

--- Disable git integration permanently
function M.disable_git_integration()
  log.line("git", "disabling git integration")
  M.purge_state()
  M.config.git.enable = false
end

function M.setup(opts)
  M.config.git = opts.git
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
