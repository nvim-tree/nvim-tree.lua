local core = require "nvim-tree.core"
local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"

local M = {}

local function is_file_readable(fname)
  local stat = vim.loop.fs_stat(fname)
  return stat and stat.type == "file" and vim.loop.fs_access(fname, "R")
end

--- Find file or buffer
--- @param opts ApiTreeFindFileOpts|nil|boolean legacy -> opts.open
--- @param bufnr number|nil legacy -> opts.bufnr
--- @param bang boolean|nil legacy -> opts.update_root
function M.fn(opts, bufnr, bang)
  -- legacy arguments
  if type(opts) == "boolean" then
    opts = {
      open = opts,
    }
    if type(bufnr) == "number" then
      opts.bufnr = bufnr
    end
    if type(bang) == "boolean" then
      opts.update_root = bang
    end
  end
  opts = opts or {}

  -- do nothing if closed and open not requested
  if not opts.open and not core.get_explorer() then
    return
  end

  -- determine the (current) buffer path
  opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(opts.bufnr) then
    return
  end
  local bufname = vim.api.nvim_buf_get_name(opts.bufnr)
  local filepath = utils.canonical_path(vim.fn.fnamemodify(bufname, ":p"))
  if not is_file_readable(filepath) then
    return
  end

  -- open or focus
  if opts.open then
    if view.is_visible() then
      lib.set_target_win()
      view.focus()
    else
      lib.open { current_window = opts.current_window }
    end
  end

  -- update root
  if opts.update_root or M.config.update_focused_file.update_root then
    require("nvim-tree").change_root(filepath, opts.bufnr)
  end

  -- find
  require("nvim-tree.actions.finders.find-file").fn(filepath)
end

function M.setup(opts)
  M.config = opts or {}
end

return M
