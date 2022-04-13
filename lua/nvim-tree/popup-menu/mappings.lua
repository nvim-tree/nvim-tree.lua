local a = vim.api

local M = {}

M.mappings = {
  ['<Esc>'] = require("nvim-tree.popup-menu").test
}

for k, v in pairs(M.mappings) do
  if M.bufnr ~= 0 or nil then
    a.nvim_buf_set_keymap(
      M.bufnr, 
      'n', k,
      string.format([[:lua %s]], v), { noremap = true, silent = true })
    end
end
return M
