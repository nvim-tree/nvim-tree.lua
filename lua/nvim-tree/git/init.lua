local utils = require "nvim-tree.utils"
local git_utils = require "nvim-tree.git.utils"
local Runner = require "nvim-tree.git.runner"
local Watcher = require("nvim-tree.watcher").Watcher

local M = {
  config = nil,
  projects = {},
  cwd_to_project_root = {},
}

function M.reload()
  if not M.config.enable then
    return {}
  end

  for project_root in pairs(M.projects) do
    M.reload_project(project_root)
  end

  return M.projects
end

function M.reload_project(project_root)
  local project = M.projects[project_root]
  if not project or not M.config.enable then
    return
  end

  local watcher = M.projects[project_root].watcher
  M.projects[project_root] = {}
  local git_status = Runner.run {
    project_root = project_root,
    list_untracked = git_utils.should_show_untracked(project_root),
    list_ignored = true,
    timeout = M.config.timeout,
  }
  M.projects[project_root] = {
    files = git_status,
    dirs = git_utils.file_status_to_dir_status(git_status, project_root),
    watcher = watcher,
  }
end

function M.get_project(project_root)
  return M.projects[project_root]
end

function M.get_project_root(cwd)
  if M.cwd_to_project_root[cwd] then
    return M.cwd_to_project_root[cwd]
  end

  if M.cwd_to_project_root[cwd] == false then
    return nil
  end

  local project_root = git_utils.get_toplevel(cwd)
  return project_root
end

function M.reload_tree_at(project_root)
  local root_node = utils.get_node_from_path(project_root)
  if not root_node then
    return
  end

  M.reload_project(project_root)
  local project = M.get_project(project_root)

  local project_files = project.files and project.files or {}
  local project_dirs = project.dirs and project.dirs or {}

  local function iterate(n)
    local parent_ignored = n.git_status == "!!"
    for _, node in pairs(n.nodes) do
      node.git_status = project_dirs[node.absolute_path] or project_files[node.absolute_path]
      if not node.git_status and parent_ignored then
        node.git_status = "!!"
      end

      if node.nodes and #node.nodes > 0 then
        iterate(node)
      end
    end
  end

  iterate(root_node)
end

function M.load_project_status(cwd)
  if not M.config.enable then
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
    timeout = M.config.timeout,
  }
  M.projects[project_root] = {
    files = git_status,
    dirs = git_utils.file_status_to_dir_status(git_status, project_root),
    watcher = Watcher.new {
      absolute_path = utils.path_join { project_root, ".git" },
      on_event = function()
        utils.debounce(200, function()
          M.reload_tree_at(project_root)
          require("nvim-tree.renderer").draw()
        end)
      end,
    },
  }
  return M.projects[project_root]
end

function M.setup(opts)
  M.config = opts.git
end

return M
