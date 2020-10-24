local explorer = nil

return {
  setup = require'nvim-tree.config'.setup,
  open = function()
    explorer = require'nvim-tree.explorer'.Explorer:new()
    local lines, highlights = require'nvim-tree.format'.format_nodes(explorer.node_tree)
    require'nvim-tree.buffers.tree'.open()
    require'nvim-tree.buffers.tree'.render(lines, highlights)
  end,
  close = require'nvim-tree.buffers.tree'.close,
  open_file = function()
    local node, idx = explorer:get_node_under_cursor()
    if node.entries and not node.opened and #node.entries == 0 then
      explorer:explore_children(node, idx)
      local lines, highlights = require'nvim-tree.format'.format_nodes(explorer.node_tree)
      require'nvim-tree.buffers.tree'.render(lines, highlights)
    end
  end,
  ex = function() return explorer end
}
