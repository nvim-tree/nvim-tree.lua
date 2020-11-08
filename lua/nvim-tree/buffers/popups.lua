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

function M.create(node, row)
  local prev_win = a.nvim_get_current_win()
  local prev_win_width = a.nvim_win_get_width(prev_win)

  local numcol = 2
  local cwd = node.absolute_path
  if node.parent then
    local tmp = node.parent
    while tmp do
      tmp = tmp.parent
      numcol = numcol + 2
    end
  end
  if node.opened then
    numcol = numcol + 2
  else
    cwd = node.absolute_path:gsub(vim.pesc(node.name)..'$', '')
  end

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

  a.nvim_buf_attach(buf, false, {
    on_detach = vim.schedule_wrap(require'nvim-tree.actions'.redraw)
  })

  vim.cmd "startinsert"

  a.nvim_buf_set_keymap(buf, 'i', '<esc>', '<esc>:bd!<cr>', {silent=true});
  a.nvim_buf_set_keymap(buf, 'i', '<C-c>', '<esc>:bd!<cr>', {silent=true});
  a.nvim_buf_set_keymap(buf, 'i', '<C-]>', '<esc>:bd!<cr>', {silent=true});
  a.nvim_buf_set_keymap(buf, 'n', 'q', ':bd!<Cr>', {silent=true});
  a.nvim_buf_set_keymap(
    buf,
    'i',
    '<CR>',
    '<esc>:lua require"nvim-tree.fs".create("'..cwd..'")<cr>',
    {
      noremap = true,
      silent = true
    });
end

return M
