local uv = vim.loop

local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local git_utils = require "nvim-tree.git.utils"
local Runner = require "nvim-tree.git.runner"
local Watcher = require("nvim-tree.watcher").Watcher
local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {
  config = {},
  projects = {},
  cwd_to_project_root = {},
}

function M.reload()
  if not M.config.git.enable then
    return {}
  end

  for project_root in pairs(M.projects) do
    M.reload_project(project_root)
  end

  return M.projects
end

function M.reload_project(project_root, path)
  local project = M.projects[project_root]
  if not project or not M.config.git.enable then
    return
  end

  if path and path:find(project_root, 1, true) ~= 1 then
    return
  end

  local git_status = Runner.run {
    project_root = project_root,
    path = path,
    list_untracked = git_utils.should_show_untracked(project_root),
    list_ignored = true,
    timeout = M.config.git.timeout,
  }

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

function M.get_project(project_root)
  return M.projects[project_root]
end

function M.get_project_root(cwd)
  if not M.config.git.enable then
    return nil
  end

  if M.cwd_to_project_root[cwd] then
    return M.cwd_to_project_root[cwd]
  end

  if M.cwd_to_project_root[cwd] == false then
    return nil
  end

  local stat, _ = uv.fs_stat(cwd)
  if not stat or stat.type ~= "directory" then
    return nil
  end

  M.cwd_to_project_root[cwd] = git_utils.get_toplevel(cwd)
  return M.cwd_to_project_root[cwd]
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

  M.reload_project(project_root)
  local project = M.get_project(project_root)

  local project_files = project.files and project.files or {}
  local project_dirs = project.dirs and project.dirs or {}

  Iterator.builder(root_node.nodes)
    :hidden()
    :applier(function(node)
      local parent_ignored = node.parent.git_status == "!!"
      node.git_status = project_dirs[node.absolute_path] or project_files[node.absolute_path]
      if not node.git_status and parent_ignored then
        node.git_status = "!!"
      end
    end)
    :recursor(function(node)
      return node.nodes and #node.nodes > 0 and node.nodes
    end)
    :iterate()

  require("nvim-tree.renderer").draw()
end

function M.load_project_status(cwd)
  if not M.config.git.enable then
    return {}
  end

  local project_root = M.get_project_root(cwd)
  if not project_root then
    M.cwd_to_project_root[cwd] = false
    return {}
  end

  local status = M.projects[project_root]
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
        reload_tree_at(w.project_root)
      end)
    end

    watcher = Watcher:new(utils.path_join { project_root, ".git" }, callback, {
      project_root = project_root,
    })
  end

  M.projects[project_root] = {
    files = git_status,
    dirs = git_utils.file_status_to_dir_status(git_status, project_root),
    watcher = watcher,
  }
  return M.projects[project_root]
end

function M.purge_state()
  M.projects = {}
  M.cwd_to_project_root = {}
end

function M.setup(opts)
  M.config.git = opts.git
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
