local core = require("nvim-tree.core")
local lib = require("nvim-tree.lib")
local finders_find_file = require("nvim-tree.actions.finders.find-file")

local M = {}

---Open the tree, focusing if already open.
---@param opts ApiTreeOpenOpts|nil|string legacy -> opts.path
function M.fn(opts)
  -- legacy arguments
  if type(opts) == "string" then
    opts = {
      path = opts,
    }
  end
  opts = opts or {}

  local previous_buf = vim.api.nvim_get_current_buf()
  local previous_path = vim.api.nvim_buf_get_name(previous_buf)

  -- sanitise path
  if type(opts.path) ~= "string" or vim.fn.isdirectory(opts.path) == 0 then
    opts.path = nil
  end

  local explorer = core.get_explorer()

  if explorer and explorer.view:is_visible() then
    -- focus
    lib.set_target_win()
    explorer.view:focus()
  else
    -- open
    lib.open({
      path = opts.path,
      current_window = opts.current_window,
      winid = opts.winid,
    })
  end

  -- find file
  if M.config.update_focused_file.enable or opts.find_file then
    -- update root
    if opts.update_root then
      require("nvim-tree").change_root(previous_path, previous_buf)
    end

    -- find
    finders_find_file.fn(previous_path)
  end
end

function M.setup(opts)
  M.config = opts or {}
end

return M
