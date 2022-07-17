local events = require "nvim-tree.events"
local explorer = require "nvim-tree.explorer"
local live_filter = require "nvim-tree.live-filter"
local view = require "nvim-tree.view"

local M = {}

TreeExplorer = nil
local first_init_done = false

function M.init(foldername)
  if TreeExplorer then
    TreeExplorer:destroy()
  end
  TreeExplorer = explorer.Explorer.new(foldername)
  if not first_init_done then
    events._dispatch_ready()
    first_init_done = true
  end
end

function M.get_explorer()
  return TreeExplorer
end

function M.get_cwd()
  return TreeExplorer.absolute_path
end

function M.get_nodes_starting_line()
  local offset = 1
  if view.is_root_folder_visible(M.get_cwd()) then
    offset = offset + 1
  end
  if live_filter.filter then
    return offset + 1
  end
  return offset
end

return M
