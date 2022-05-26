local core = require "nvim-tree.core"
local renderer = require "nvim-tree.renderer"

local M = {}

local function expand(node)
  node.open = true
  if #node.nodes == 0 then
    core.get_explorer():expand(node)
  end
end

local function iterate(_node)
  for _, node in pairs(_node.nodes) do
    if node.nodes and not node.open then
      expand(node)
    end

    if node.open then
      iterate(node)
    end
  end
end

function M.fn()
  iterate(core.get_explorer())
  renderer.draw()
end

return M
