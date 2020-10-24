local explorer = nil

return {
  setup = require'nvim-tree.config'.setup,
  open = function()
    explorer = require'nvim-tree.explorer'.Explorer:new()
    require'nvim-tree.buffers.tree'.open()
  end,
  close = require'nvim-tree.buffers.tree'.close,
  ex = function() return explorer end
}
