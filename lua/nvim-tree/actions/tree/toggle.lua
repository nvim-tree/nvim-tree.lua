local view = require "nvim-tree.view"
local open = require "nvim-tree.actions.tree.open"
local find_file = require "nvim-tree.actions.tree.find-file"

local M = {}

---Toggle the tree.
---@param opts ApiTreeToggleOpts|nil|boolean
function M.fn(opts, no_focus, cwd, bang)
  -- legacy arguments
  if type(opts) == "boolean" then
    opts = {
      find_file = opts,
    }
    if type(cwd) == "string" then
      opts.path = cwd
    end
    if type(no_focus) == "boolean" then
      opts.focus = not no_focus
    end
    if type(bang) == "boolean" then
      opts.update_root = bang
    end
  end

  opts = opts or {}

  -- defaults
  if opts.focus == nil then
    opts.focus = true
  end

  -- sanitise path
  if type(opts.path) ~= "string" or vim.fn.isdirectory(opts.path) == 0 then
    opts.path = nil
  end

  if view.is_visible() then
    view.close()
  else
    local previous_buf = vim.api.nvim_get_current_buf()
    open.fn { path = opts.path, current_window = opts.current_window }
    if M.config.update_focused_file.enable or opts.find_file then
      find_file.fn(false, previous_buf, opts.update_root)
    end
    if not opts.focus then
      vim.cmd "noautocmd wincmd p"
    end
  end
end

function M.setup(opts)
  M.config = opts or {}
end

return M
