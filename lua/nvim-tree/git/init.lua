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

  -- index of paths inside toplevels, false when not inside a toplevel
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

local function reload_git_status(project_root, path, project, git_status)
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

  project.dirs = git_utils.file_status_to_dir_status(project.files, project_root)
end

--- Is this path in a known ignored directory?
--- @param path string
--- @param project table git status
--- @return boolean
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

function M.reload()
  if not M.config.git.enable then
    return {}
  end

  for project_root in pairs(M._projects_by_toplevel) do
    M.reload_project(project_root)
  end

  return M._projects_by_toplevel
end

function M.reload_project(project_root, path, callback)
  local project = M._projects_by_toplevel[project_root]
  if not project or not M.config.git.enable then
    if callback then
      callback()
    end
    return
  end

  if path and (path:find(project_root, 1, true) ~= 1 or path_ignored_in_project(path, project)) then
    if callback then
      callback()
    end
    return
  end

  local opts = {
    project_root = project_root,
    path = path,
    list_untracked = git_utils.should_show_untracked(project_root),
    list_ignored = true,
    timeout = M.config.git.timeout,
  }

  if callback then
    Runner.run(opts, function(git_status)
      reload_git_status(project_root, path, project, git_status)
      callback()
    end)
  else
    -- TODO use callback once async/await is available
    local git_status = Runner.run(opts)
    reload_git_status(project_root, path, project, git_status)
  end
end

function M.get_project(project_root)
  return M._projects_by_toplevel[project_root]
end

function M.get_project_root(cwd)
  if not M.config.git.enable then
    return nil
  end

  if M._toplevels_by_path[cwd] then
    return M._toplevels_by_path[cwd]
  end

  if M._toplevels_by_path[cwd] == false then
    return nil
  end

  local stat, _ = vim.loop.fs_stat(cwd)
  if not stat or stat.type ~= "directory" then
    return nil
  end

  -- short-circuit any known ignored paths
  for root, project in pairs(M._projects_by_toplevel) do
    if project and path_ignored_in_project(cwd, project) then
      M._toplevels_by_path[cwd] = root
      return root
    end
  end

  local toplevel, git_dir = git_utils.get_toplevel(cwd)
  for _, disabled_for_dir in ipairs(M.config.git.disable_for_dirs) do
    local toplevel_norm = vim.fn.fnamemodify(toplevel, ":p")
    local disabled_norm = vim.fn.fnamemodify(disabled_for_dir, ":p")
    if toplevel_norm == disabled_norm then
      return nil
    end
  end

  M._toplevels_by_path[cwd] = toplevel
  if toplevel then
    M._git_dirs_by_toplevel[toplevel] = git_dir
  end
  return M._toplevels_by_path[cwd]
end

local function reload_tree_at(project_root)
  if not M.config.git.enable then
    return nil
  end

  log.line("watcher", "git event executing '%s'", project_root)
  local root_node = utils.get_node_from_path(project_root)
  if not root_node then
    return
  end

  M.reload_project(project_root, nil, function()
    local git_status = M.get_project(project_root)

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

function M.load_project_status(cwd)
  if not M.config.git.enable then
    return {}
  end

  local project_root = M.get_project_root(cwd)
  if not project_root then
    M._toplevels_by_path[cwd] = false
    return {}
  end

  local status = M._projects_by_toplevel[project_root]
  if status then
    return status
  end

  local git_status = Runner.run {
    project_root = project_root,
    list_untracked = git_utils.should_show_untracked(project_root),
    list_ignored = true,
    timeout = M.config.git.timeout,
  }

  local watcher = nil
  if M.config.filesystem_watchers.enable then
    log.line("watcher", "git start")

    local callback = function(w)
      log.line("watcher", "git event scheduled '%s'", w.project_root)
      utils.debounce("git:watcher:" .. w.project_root, M.config.filesystem_watchers.debounce_delay, function()
        if w.destroyed then
          return
        end
        reload_tree_at(w.project_root)
      end)
    end

    local git_dir = vim.env.GIT_DIR
      or M._git_dirs_by_toplevel[project_root]
      or utils.path_join { project_root, ".git" }
    watcher = Watcher:new(git_dir, WATCHED_FILES, callback, {
      project_root = project_root,
    })
  end

  M._projects_by_toplevel[project_root] = {
    files = git_status,
    dirs = git_utils.file_status_to_dir_status(git_status, project_root),
    watcher = watcher,
  }
  return M._projects_by_toplevel[project_root]
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
