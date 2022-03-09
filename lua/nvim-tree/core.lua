local events = require "nvim-tree.events"
local explorer = require "nvim-tree.explorer"

local M = {}

local first_init_done = false

TreeExplorer = nil

function M.init(foldername)
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
  return TreeExplorer.cwd
end

return M
