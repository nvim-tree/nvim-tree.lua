local M = {}

function M.fn()
  local function iter(nodes)
    for _, node in pairs(nodes) do
      if node.open then
        node.open = false
      end
      if node.entries then
        iter(node.entries)
      end
    end
  end

  iter(require'nvim-tree.lib'.Tree.entries)
  require'nvim-tree.lib'.redraw()
end

return M
