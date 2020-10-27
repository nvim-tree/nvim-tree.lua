local a = vim.api
local M = {}

function M.new(node, row)
  local prev_win = a.nvim_get_current_win()
  local prev_win_width = a.nvim_win_get_width(prev_win)

  local line = a.nvim_get_current_line()
  local index = vim.fn.stridx(line, node.name)
  line = line:sub(1, index)
  -- don't know why vim but maybe vim has padding so we have to add 2 here
  local numcol = vim.fn.strchars(line)+2

  local buf = a.nvim_create_buf(false, true)
  local win = a.nvim_open_win(buf, true, {
    relative = "win",
    row = row,
    col = numcol,
    win = prev_win,
    height = 1,
    width = prev_win_width - numcol,
    style = 'minimal'
  })

  print(win)
end

return M
