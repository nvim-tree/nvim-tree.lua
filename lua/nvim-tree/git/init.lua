local log = require("nvim-tree.log")
local utils = require("nvim-tree.utils")
local git_utils = require("nvim-tree.git.utils")

local GitRunner = require("nvim-tree.git.runner")
local Watcher = require("nvim-tree.watcher").Watcher
local Iterator = require("nvim-tree.iterators.node-iterator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class GitStatus -- xy short-format statuses
---@field file string?
---@field dir string[]?

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
  "HEAD",       -- local ref
  "HEAD.lock",  -- HEAD will not always be updated e.g. revert
  "config",     -- user config
  "index",      -- staging area
}

---@param toplevel string|nil
---@param path string|nil
---@param project table
---@param statuses GitXYByPath?
local function reload_git_statuses(toplevel, path, project, statuses)
  if path then
    for p in pairs(project.files) do
      if p:find(path, 1, true) == 1 then
        project.files[p] = nil
      end
    end
    project.files = vim.tbl_deep_extend("force", project.files, statuses)
  else
    project.files = statuses
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

  ---@type GitRunnerOpts
  local runner_opts = {
    toplevel = toplevel,
    path = path,
    list_untracked = git_utils.should_show_untracked(toplevel),
    list_ignored = true,
    timeout = M.config.git.timeout,
  }

  if callback then
    ---@param statuses GitXYByPath
    runner_opts.callback = function(statuses)
      reload_git_statuses(toplevel, path, project, statuses)
      callback()
    end
    GitRunner:run(runner_opts)
  else
    -- TODO #1974 use callback once async/await is available
    reload_git_statuses(toplevel, path, project, GitRunner:run(runner_opts))
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
  if not path then
    return nil
  end

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
  local toplevel_norm = vim.fn.fnamemodify(toplevel, ":p")

  -- ignore disabled paths
  if type(M.config.git.disable_for_dirs) == "table" then
    for _, disabled_for_dir in ipairs(M.config.git.disable_for_dirs) do
      local disabled_norm = vim.fn.fnamemodify(disabled_for_dir, ":p")
      if toplevel_norm == disabled_norm then
        return nil
      end
    end
  elseif type(M.config.git.disable_for_dirs) == "function" then
    if M.config.git.disable_for_dirs(toplevel_norm) then
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
  local base = utils.get_node_from_path(toplevel)
  base = base and base:as(DirectoryNode)
  if not base then
    return
  end

  M.reload_project(toplevel, nil, function()
    local git_status = M.get_project(toplevel)

    Iterator.builder(base.nodes)
      :hidden()
      :applier(function(node)
        local parent_ignored = node.parent and node.parent:is_git_ignored() or false
        node:update_git_status(parent_ignored, git_status)
      end)
      :recursor(function(node)
        local dir = node:as(DirectoryNode)
        return dir and #dir.nodes > 0 and dir.nodes
      end)
      :iterate()

    base.explorer.renderer:draw()
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

  local statuses = GitRunner:run({
    toplevel = toplevel,
    list_untracked = git_utils.should_show_untracked(toplevel),
    list_ignored = true,
    timeout = M.config.git.timeout,
  })

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

    local git_dir = vim.env.GIT_DIR or M._git_dirs_by_toplevel[toplevel] or utils.path_join({ toplevel, ".git" })
    watcher = Watcher:new(git_dir, WATCHED_FILES, callback, {
      toplevel = toplevel,
    })
  end

  if statuses then
    M._projects_by_toplevel[toplevel] = {
      files = statuses,
      dirs = git_utils.file_status_to_dir_status(statuses, toplevel),
      watcher = watcher,
    }
    return M._projects_by_toplevel[toplevel]
  else
    M._toplevels_by_path[path] = false
    return {}
  end
end

---@param dir DirectoryNode
---@param project table?
---@param root string?
function M.update_parent_statuses(dir, project, root)
  while project and dir do
    -- step up to the containing project
    if dir.absolute_path == root then
      -- stop at the top of the tree
      if not dir.parent then
        break
      end

      root = M.get_toplevel(dir.parent.absolute_path)

      -- stop when no more projects
      if not root then
        break
      end

      -- update the containing project
      project = M.get_project(root)
      M.reload_project(root, dir.absolute_path, nil)
    end

    -- update status
    dir:update_git_status(dir.parent and dir.parent:is_git_ignored() or false, project)

    -- maybe parent
    dir = dir.parent
  end
end

---Refresh contents and git status for a single directory
---@param dir DirectoryNode
function M.refresh_dir(dir)
  local node = dir:get_parent_of_group() or dir
  local toplevel = M.get_toplevel(dir.absolute_path)

  M.reload_project(toplevel, dir.absolute_path, function()
    local project = M.get_project(toplevel) or {}

    dir.explorer:reload(node, project)

    M.update_parent_statuses(dir, project, toplevel)

    dir.explorer.renderer:draw()
  end)
end

---@param n DirectoryNode
---@param projects table
function M.reload_node_status(n, projects)
  local toplevel = M.get_toplevel(n.absolute_path)
  local status = projects[toplevel] or {}
  for _, node in ipairs(n.nodes) do
    node:update_git_status(n:is_git_ignored(), status)
    local dir = node:as(DirectoryNode)
    if dir and #dir.nodes > 0 then
      dir:reload_node_status(projects)
    end
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
