local lib = require "nvim-tree.lib"
local view = require "nvim-tree.view"

local M = {}

---Open the tree, focusing if already open.
---@param opts ApiTreeOpenOpts|nil|string
function M.fn(opts)
  -- legacy arguments
  if type(opts) == "string" then
    opts = {
      path = opts,
    }
  end

  opts = opts or {}

  local previous_buf = vim.api.nvim_get_current_buf()

  -- sanitise path
  if type(opts.path) ~= "string" or vim.fn.isdirectory(opts.path) == 0 then
    opts.path = nil
  end

  if view.is_visible() then
    lib.set_target_win()
    view.focus()
  else
    lib.open(opts)
  end

  if M.config.update_focused_file.enable or opts.find_file then
    require("nvim-tree.actions.tree.find-file").fn(false, previous_buf, opts.update_root)
  end
end

function M.setup(opts)
  M.config = opts or {}
end

return M
