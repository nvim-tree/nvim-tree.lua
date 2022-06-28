local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local git = require "nvim-tree.git"
local Watcher = require("nvim-tree.watcher").Watcher

local M = {}

local function reload_and_get_git_project(path)
  local project_root = git.get_project_root(path)
  git.reload_project(project_root, path)
  return project_root, git.get_project(project_root) or {}
end

local function update_parent_statuses(node, project, root)
  while project and node and node.absolute_path ~= root do
    require("nvim-tree.explorer.common").update_git_status(node, false, project)
    node = node.parent
  end
end

local function is_git(path)
  return path:match "%.git$" ~= nil or path:match(utils.path_add_trailing ".git") ~= nil
end

local function refresh_path(path)
  log.line("watcher", "node event executing '%s'", path)
  local n = utils.get_node_from_path(path)
  if not n then
    return
  end

  local node = utils.get_parent_of_group(n)
  local project_root, project = reload_and_get_git_project(path)
  require("nvim-tree.explorer.reload").reload(node, project)
  update_parent_statuses(node, project, project_root)

  require("nvim-tree.renderer").draw()
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
    on_event = function(opts)
      log.line("watcher", "node event scheduled '%s'", opts.absolute_path)
      utils.debounce("explorer:watch:" .. opts.absolute_path, M.debounce_delay, function()
        refresh_path(opts.absolute_path)
      end)
    end,
  }
end

function M.setup(opts)
  M.enabled = opts.filesystem_watchers.enable
  M.interval = opts.filesystem_watchers.interval
  M.debounce_delay = opts.filesystem_watchers.debounce_delay
end

return M
