local a = vim.api
local M = {}

function M.rename(node, row)
  local prev_win = a.nvim_get_current_win()
  local prev_win_width = a.nvim_win_get_width(prev_win)

  local line = a.nvim_get_current_line()
  local index = vim.fn.stridx(line, node.name)
  line = line:sub(1, index)
  local numcol = vim.fn.strchars(line)+2

  local buf = a.nvim_create_buf(false, true)
  a.nvim_open_win(buf, true, {
    relative = "win",
    row = row,
    col = numcol,
    win = prev_win,
    height = 1,
    width = prev_win_width - numcol,
    style = 'minimal'
  })

  vim.cmd "startinsert"

  a.nvim_buf_set_keymap(buf, 'i', '<esc>', '<esc>:q<cr>', {});
  a.nvim_buf_set_keymap(buf, 'i', '<C-c>', '<esc>:q<cr>', {});
  a.nvim_buf_set_keymap(buf, 'i', '<C-]>', '<esc>:q<cr>', {});
  a.nvim_buf_set_keymap(buf, 'n', 'q', ':q<Cr>', {});
  a.nvim_buf_set_keymap(
    buf,
    'i',
    '<CR>',
    '<esc>:lua require"nvim-tree.fs".rename("'..node.name..'")<cr>',
    {
      noremap = true,
      silent = true
    });
end

return M
