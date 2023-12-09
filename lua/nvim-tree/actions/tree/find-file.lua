local core = require "nvim-tree.core"
local lib = require "nvim-tree.lib"
local view = require "nvim-tree.view"
local finders_find_file = require "nvim-tree.actions.finders.find-file"

local M = {}

--- Find file or buffer
---@param opts ApiTreeFindFileOpts|nil|boolean legacy -> opts.buf
function M.fn(opts)
  -- legacy arguments
  if type(opts) == "string" then
    opts = {
      buf = opts,
    }
  end
  opts = opts or {}

  -- do nothing if closed and open not requested
  if not opts.open and not core.get_explorer() then
    return
  end

  local bufnr, path

  -- (optional) buffer number and path
  if type(opts.buf) == "nil" then
    bufnr = vim.api.nvim_get_current_buf()
    path = vim.api.nvim_buf_get_name(bufnr)
  elseif type(opts.buf) == "number" then
    if not vim.api.nvim_buf_is_valid(opts.buf) then
      return
    end
    bufnr = tonumber(opts.buf)
    path = vim.api.nvim_buf_get_name(bufnr)
  elseif type(opts.buf) == "string" then
    bufnr = nil
    path = tostring(opts.buf)
  else
    return
  end

  if view.is_visible() then
    -- focus
    if opts.focus then
      lib.set_target_win()
      view.focus()
    end
  elseif opts.open then
    -- open
    lib.open { current_window = opts.current_window, winid = opts.winid }
    if not opts.focus then
      vim.cmd "noautocmd wincmd p"
    end
  end

  -- update root
  if opts.update_root or M.config.update_focused_file.update_root then
    require("nvim-tree").change_root(path, bufnr)
  end

  -- find
  finders_find_file.fn(path)
end

function M.setup(opts)
  M.config = opts or {}
end

return M
