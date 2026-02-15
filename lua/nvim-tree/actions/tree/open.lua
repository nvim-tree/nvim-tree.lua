local lib = require("nvim-tree.lib")
local view = require("nvim-tree.view")
local finders_find_file = require("nvim-tree.actions.finders.find-file")

local M = {}

---Open the tree, focusing if already open.
---@param opts? nvim_tree.api.tree.open.Opts|string legacy -> opts.path
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

  if view.is_visible() then
    -- focus
    lib.set_target_win()
    view.focus()
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
