local M = {}

function M.setup(opts)
  require'nvim-tree.actions.system-open'.setup(opts.system_open)
  require'nvim-tree.actions.trash'.setup(opts.trash)
end

return M
