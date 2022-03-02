local a = vim.api
local uv = vim.loop

local M = {}

local function get_formatted_lines(cwd)
  local stats = uv.fs_stat(cwd)

  return {
    ' fullpath: ' .. cwd,
    ' created:  ' .. os.date("%x %X", stats.birthtime.sec),
    ' modified: ' .. os.date("%x %X", stats.mtime.sec),
    ' accessed: ' .. os.date("%x %X", stats.atime.sec),
    ' size:     ' .. stats.size .. ' bytes',
    ' mode:     ' .. string.format('%o', stats.mode),
  }
end

local winnr = nil

local function setup_window(lines)
  local max_width = vim.fn.max(vim.tbl_map(function(n) return #n end, lines))
  winnr = a.nvim_open_win(0, false, {
    col = 1,
    row = 1,
    relative = "cursor",
    width = max_width + 1,
    height = #lines,
    border = 'shadow',
    noautocmd = true,
    style = 'minimal'
  })
  local bufnr = a.nvim_create_buf(false, true)
  a.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  a.nvim_win_set_buf(winnr, bufnr)
end

function M.close_popup()
  if winnr ~= nil then
    a.nvim_win_close(winnr, { force = true })
    vim.cmd "augroup NvimTreeRemoveFilePopup | au! CursorMoved | augroup END"

    winnr = nil
  end
end

function M.show_file_info()
  M.close_popup()

  local node = require'nvim-tree.lib'.get_node_at_cursor()
  if not node or not node.absolute_path then
    return
  end

  local lines = get_formatted_lines(node.absolute_path)
  setup_window(lines)

  vim.cmd [[
    augroup NvimTreeRemoveFilePopup
      au CursorMoved * lua require'nvim-tree.actions.file-popup'.close_popup()
    augroup END
  ]]
end

return M
