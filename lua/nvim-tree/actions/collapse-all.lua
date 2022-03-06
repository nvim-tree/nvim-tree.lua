local renderer = require "nvim-tree.renderer"

local M = {}

function M.fn()
  local function iter(nodes)
    for _, node in pairs(nodes) do
      if node.open then
        node.open = false
      end
      if node.nodes then
        iter(node.nodes)
      end
    end
  end

  iter(TreeExplorer.nodes)
  renderer.draw()
end

return M
