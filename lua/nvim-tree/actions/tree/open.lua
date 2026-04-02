local lib = require("nvim-tree.lib")
local view = require("nvim-tree.view")
local core = require("nvim-tree.core")
local config = require("nvim-tree.config")
local finders_find_file = require("nvim-tree.actions.finders.find-file")
local change_root = require("nvim-tree.actions.tree.change-root")

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
  if config.g.update_focused_file.enable or opts.find_file then
    -- update root
    if opts.update_root then
      change_root.fn(previous_path, previous_buf)
    end

    -- find
    finders_find_file.fn(previous_path)
  end
end

---@param dirname string absolute directory path
function M.open_on_directory(dirname)
  local should_proceed = config.g.hijack_directories.auto_open or view.is_visible()
  if not should_proceed then
    return
  end

  -- instantiate an explorer if there is not one
  if not core.get_explorer() then
    core.init(dirname)
  end

  local explorer = core.get_explorer()
  if explorer then
    explorer:force_dirchange(dirname, true, false)
  end
end

function M.tab_enter()
  if view.is_visible({ any_tabpage = true }) then
    local bufname = vim.api.nvim_buf_get_name(0)

    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 }) or ""

    for _, filter in ipairs(config.g.tab.sync.ignore) do
      if bufname:match(filter) ~= nil or ft:match(filter) ~= nil then
        return
      end
    end
    view.open({ focus_tree = false })

    local explorer = core.get_explorer()
    if explorer then
      explorer.renderer:draw()
    end
  end
end

return M
