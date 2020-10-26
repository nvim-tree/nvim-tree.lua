local explorer = nil

return {
  setup = require'nvim-tree.config'.setup,
  close = require'nvim-tree.buffers.tree'.close,
  redraw = function()
    local buffers_tree = require'nvim-tree.buffers.tree'
    vim.defer_fn(
      function()
        local should_redraw = #vim.tbl_keys(buffers_tree.windows) > 0
        if should_redraw then
          buffers_tree.open()
        end
      end, 1)
  end,
  open = function()
    explorer = require'nvim-tree.explorer'.Explorer:new()
    local lines, highlights = require'nvim-tree.format'.format_nodes(explorer.node_tree)
    if require'nvim-tree.buffers.tree'.open() == 'norestore' then
      require'nvim-tree.buffers.tree'.render(lines, highlights)
    end
  end,
  open_file = function()
    local node, idx = explorer:get_node_under_cursor()
    if node.entries ~= nil then
      explorer:switch_open_dir(node, idx)
      local lines, highlights = require'nvim-tree.format'.format_nodes(explorer.node_tree)
      require'nvim-tree.buffers.tree'.render(lines, highlights)
    end
  end,
  ex = function() return explorer end
}
