local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local git_utils = require "nvim-tree.git.utils"
local Runner = require "nvim-tree.git.runner"
local Watcher = require("nvim-tree.watcher").Watcher
local Iterator = require "nvim-tree.iterators.node-iterator"
local explorer_node = require "nvim-tree.explorer.node"

local M = {
  config = {},
}

local projects_by_toplevel = {}
local projects_by_path = {} -- false when no project

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
    local project = projects_by_toplevel[project_root]

    Iterator.builder(root_node.nodes)
      :hidden()
      :applier(function(node)
        local parent_ignored = explorer_node.is_git_ignored(node.parent)
        explorer_node.update_git_status(node, parent_ignored, project)
      end)
      :recursor(function(node)
        return node.nodes and #node.nodes > 0 and node.nodes
      end)
      :iterate()

    require("nvim-tree.renderer").draw()
  end)
end

--- Create a populated git project synchronously.
--- @param toplevel string absolute
--- @param git_dir string absolute
--- @return table project
local function create_project(toplevel, git_dir)
  local git_status = Runner.run {
    project_root = toplevel,
    list_untracked = git_utils.should_show_untracked(toplevel),
    list_ignored = true,
    timeout = M.config.git.timeout,
  }

  local project = {
    toplevel = toplevel,
    git_dir = git_dir,
    files = git_status,
    dirs = git_utils.file_status_to_dir_status(git_status, toplevel),
  }
  projects_by_toplevel[toplevel] = project

  if M.config.filesystem_watchers.enable then
    log.line("watcher", "git start")

    local callback = function(w)
      log.line("watcher", "git event scheduled '%s'", w.project_root)
      utils.debounce("git:watcher:" .. w.project_root, M.config.filesystem_watchers.debounce_delay, function()
        if w.destroyed then
          return
        end
        reload_tree_at(w.toplevel)
      end)
    end

    project.watcher = Watcher:new(git_dir, WATCHED_FILES, callback, {
      toplevel = toplevel,
    })
  end

  return project
end

--- Find an project known for a path.
--- @param path string absolute
--- @return table|nil project
local function find_project(path)
  -- known
  if projects_by_path[path] then
    return projects_by_path[path]
  end

  -- ignore non-directories
  local stat, _ = vim.loop.fs_stat(path)
  if not stat or stat.type ~= "directory" then
    projects_by_path[path] = false
    return nil
  end

  -- short-circuit any known ignored paths
  for _, project in pairs(projects_by_toplevel) do
    if project and path_ignored_in_project(path, project) then
      projects_by_path[path] = project
      return project
    end
  end

  return nil
end

--- Reload all git projects
function M.reload()
  if not M.config.git.enable then
    return {}
  end

  for _, project in pairs(projects_by_toplevel) do
    M.reload_project(project, nil, nil)
  end
end

--- Reload the git project.
--- @param project table|nil
--- @param path string|nil only reload this path, NOP if this path is ignored
--- @param callback function|nil no arguments
function M.reload_project(project, path, callback)
  if not project or not M.config.git.enable then
    if callback then
      callback()
    end
    return
  end

  if path and (path:find(project.toplevel, 1, true) ~= 1 or path_ignored_in_project(path, project)) then
    if callback then
      callback()
    end
    return
  end

  local opts = {
    project_root = project.toplevel,
    path = path,
    list_untracked = git_utils.should_show_untracked(project.toplevel),
    list_ignored = true,
    timeout = M.config.git.timeout,
  }

  if callback then
    Runner.run(opts, function(git_status)
      reload_git_status(project.toplevel, path, project, git_status)
      callback()
    end)
  else
    -- TODO use callback once async/await is available
    local git_status = Runner.run(opts)
    reload_git_status(project.toplevel, path, project, git_status)
  end
end

--- Retrieve the project containing a path, creating and populating if necessary.
--- @param path string absolute
--- @return table|nil project
function M.get_project(path)
  if not M.config.git.enable then
    return nil
  end

  -- existing project known for this path
  local project = find_project(path)
  if project then
    return project
  end

  -- determine git directories
  local toplevel, git_dir = git_utils.get_toplevel(path)
  if not toplevel or not git_dir then
    projects_by_path[path] = false
    return nil
  end

  -- exisiting project unknown for this path
  project = projects_by_toplevel[toplevel]
  if project then
    projects_by_path[path] = project
    return project
  end

  -- lazily create the new project
  project = create_project(toplevel, git_dir)
  projects_by_path[path] = project
  return project
end

function M.purge_state()
  log.line("git", "purge_state")
  -- TODO 2382 we never tore down the watcher
  projects_by_toplevel = {}
  projects_by_path = {}
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
