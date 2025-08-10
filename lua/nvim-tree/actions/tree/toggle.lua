local lib = require("nvim-tree.lib")
local view = require("nvim-tree.view")
local finders_find_file = require("nvim-tree.actions.finders.find-file")

local M = {}

---Toggle the tree.
---@param opts ApiTreeToggleOpts|nil|boolean legacy -> opts.find_file
---@param no_focus string|nil legacy -> opts.focus
---@param cwd boolean|nil legacy -> opts.path
---@param bang boolean|nil legacy -> opts.update_root
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

  local previous_buf = vim.api.nvim_get_current_buf()
  local previous_path = vim.api.nvim_buf_get_name(previous_buf)

  -- sanitise path
  if type(opts.path) ~= "string" or vim.fn.isdirectory(opts.path) == 0 then
    opts.path = nil
  end

  if view.is_visible() then
    -- close
    view.close()
  else
    -- open
    lib.open({
      path = opts.path,
      current_window = opts.current_window,
      winid = opts.winid,
    })

    -- find file
    if M.config.update_focused_file.enable or opts.find_file then
      -- update root
      if opts.update_root then
        require("nvim-tree").change_root(previous_path, previous_buf)
      end

      -- find
      finders_find_file.fn(previous_path)
    end

    -- restore focus
    if not opts.focus then
      vim.cmd("noautocmd wincmd p")
    end
  end
end

function M.setup(opts)
  M.config = opts or {}
end

return M
