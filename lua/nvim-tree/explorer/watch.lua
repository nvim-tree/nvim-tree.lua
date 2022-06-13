local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local git = require "nvim-tree.git"
local Watcher = require("nvim-tree.watcher").Watcher

local M = {
  running_project = {},
  pending_project = {},
}

local function update_parent_statuses(node, project, root)
  while project and node and node.absolute_path ~= root do
    require("nvim-tree.explorer.common").update_git_status(node, false, project)
    node = node.parent
  end
end

local function is_git(path)
  return path:match "%.git$" ~= nil or path:match(utils.path_add_trailing ".git") ~= nil
end

function M.create_watcher(absolute_path)
  if not M.enabled then
    return nil
  end
  if is_git(absolute_path) then
    return nil
  end

  log.line("watcher", "node start '%s'", absolute_path)
  Watcher.new {
    absolute_path = absolute_path,
    interval = M.interval,
    on_event = function(path)
      log.line("watcher", "node event '%s'", path)
      local n = utils.get_node_from_path(absolute_path)
      if not n then
        return
      end

      local project_root = git.get_project_root(path)

      if M.running_project[project_root] then
        log.line("watcher", "node pending '%s'", path)
        M.pending_project[project_root] = true
        return
      end
      M.running_project[project_root] = true

      git.reload_project(project_root)

      if M.pending_project[project_root] then
        log.line("watcher", "node rerunning '%s'", path)
        git.reload_project(project_root)
      end
      M.pending_project[project_root] = nil
      M.running_project[project_root] = nil

      local project = git.get_project(project_root) or {}
      local node = utils.get_parent_of_group(n)
      require("nvim-tree.explorer.reload").reload(node, project)
      update_parent_statuses(node, project, project_root)

      require("nvim-tree.renderer").draw()

      log.line("watcher", "node done '%s'", path)
    end,
  }
end

function M.setup(opts)
  M.enabled = opts.filesystem_watchers.enable
  M.interval = opts.filesystem_watchers.interval
end

return M
