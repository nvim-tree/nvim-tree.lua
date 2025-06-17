local utils = require("nvim-tree.utils")

local M = {}

---@param node Node
---@return table
local function get_formatted_lines(node)
  local stats = node.fs_stat
  if stats == nil then
    return {
      "",
      "  Can't retrieve file information",
      "",
    }
  end

  local fpath = " fullpath: " .. node.absolute_path
  local created_at = " created:  " .. os.date("%x %X", stats.birthtime.sec)
  local modified_at = " modified: " .. os.date("%x %X", stats.mtime.sec)
  local accessed_at = " accessed: " .. os.date("%x %X", stats.atime.sec)
  local size = " size:     " .. utils.format_bytes(stats.size)

  return {
    fpath,
    size,
    accessed_at,
    modified_at,
    created_at,
  }
end

local current_popup = nil

---@param node Node
local function setup_window(node)
  local lines = get_formatted_lines(node)

  local max_width = vim.fn.max(vim.tbl_map(function(n)
    return #n
  end, lines))
  local open_win_config = vim.tbl_extend("force", M.open_win_config, {
    width = max_width + 1,
    height = #lines,
    noautocmd = true,
    zindex = 60,
  })
  local winnr = vim.api.nvim_open_win(0, false, open_win_config)
  current_popup = {
    winnr = winnr,
    file_path = node.absolute_path,
  }
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_win_set_buf(winnr, bufnr)
end

function M.close_popup()
  if current_popup ~= nil then
    if vim.api.nvim_win_is_valid(current_popup.winnr) then
      vim.api.nvim_win_close(current_popup.winnr, true)
    end
    vim.cmd("augroup NvimTreeRemoveFilePopup | au! CursorMoved | augroup END")

    current_popup = nil
  end
end

---@param node Node
function M.toggle_file_info(node)
  if node.name == ".." then
    return
  end
  if current_popup ~= nil then
    local is_same_node = current_popup.file_path == node.absolute_path

    M.close_popup()

    if is_same_node then
      return
    end
  end

  setup_window(node)

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = vim.api.nvim_create_augroup("NvimTreeRemoveFilePopup", {}),
    callback = M.close_popup,
  })
end

function M.setup(opts)
  M.open_win_config = opts.actions.file_popup.open_win_config
end

return M
