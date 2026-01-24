local view = require("nvim-tree.view")
local core = require("nvim-tree.core")
local notify = require("nvim-tree.notify")

---@class LibOpenOpts
---@field path string|nil path
---@field current_window boolean|nil default false
---@field winid number|nil

local M = {
  target_winid = nil,
}

function M.set_target_win()
  local id = vim.api.nvim_get_current_win()
  local tree_id = view.get_winnr()
  if tree_id and id == tree_id then
    M.target_winid = 0
    return
  end

  M.target_winid = id
end

---@param cwd string
local function handle_buf_cwd(cwd)
  local explorer = core.get_explorer()
  if M.respect_buf_cwd and cwd ~= core.get_cwd() and explorer then
    explorer:change_dir(cwd)
  end
end

local function open_view_and_draw()
  local cwd = vim.fn.getcwd()
  view.open()
  handle_buf_cwd(cwd)

  local explorer = core.get_explorer()
  if explorer then
    explorer.renderer:draw()
  end
end

local function should_hijack_current_buf()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  local bufmodified, ft
  if vim.fn.has("nvim-0.10") == 1 then
    bufmodified = vim.api.nvim_get_option_value("modified", { buf = bufnr })
    ft = vim.api.nvim_get_option_value("ft", { buf = bufnr })
  else
    bufmodified = vim.api.nvim_buf_get_option(bufnr, "modified") ---@diagnostic disable-line: deprecated
    ft = vim.api.nvim_buf_get_option(bufnr, "ft") ---@diagnostic disable-line: deprecated
  end

  local should_hijack_unnamed = M.hijack_unnamed_buffer_when_opening and bufname == "" and not bufmodified and ft == ""
  local should_hijack_dir = bufname ~= "" and vim.fn.isdirectory(bufname) == 1 and M.hijack_directories.enable

  return should_hijack_dir or should_hijack_unnamed
end

---@param prompt_input string
---@param prompt_select string
---@param items_short string[]
---@param items_long string[]
---@param kind string|nil
---@param callback fun(item_short: string|nil)
function M.prompt(prompt_input, prompt_select, items_short, items_long, kind, callback)
  local function format_item(short)
    for i, s in ipairs(items_short) do
      if short == s then
        return items_long[i]
      end
    end
    return ""
  end

  if M.select_prompts then
    vim.ui.select(items_short, { prompt = prompt_select, kind = kind, format_item = format_item }, function(item_short)
      callback(item_short)
    end)
  else
    vim.ui.input({ prompt = prompt_input, default = items_short[1] or "" }, function(item_short)
      if item_short then
        callback(string.lower(item_short and item_short:sub(1, 1)) or nil)
      end
    end)
  end
end

---Open the tree, initialising as needed. Maybe hijack the current buffer.
---@param opts LibOpenOpts|nil
function M.open(opts)
  opts = opts or {}

  M.set_target_win()
  if not core.get_explorer() or opts.path then
    if opts.path then
      core.init(opts.path)
    else
      local cwd, err = vim.loop.cwd()
      if not cwd then
        notify.error(string.format("current working directory unavailable: %s", err))
        return
      end
      core.init(cwd)
    end
  end

  local explorer = core.get_explorer()

  if should_hijack_current_buf() then
    view.close_this_tab_only()
    view.open_in_win()
    if explorer then
      explorer.renderer:draw()
    end
  elseif opts.winid then
    view.open_in_win({ hijack_current_buf = false, resize = false, winid = opts.winid })
    if explorer then
      explorer.renderer:draw()
    end
  elseif opts.current_window then
    view.open_in_win({ hijack_current_buf = false, resize = false })
    if explorer then
      explorer.renderer:draw()
    end
  else
    open_view_and_draw()
  end
  view.restore_tab_state()
end

function M.setup(opts)
  M.hijack_unnamed_buffer_when_opening = opts.hijack_unnamed_buffer_when_opening
  M.hijack_directories = opts.hijack_directories
  M.respect_buf_cwd = opts.respect_buf_cwd
  M.select_prompts = opts.select_prompts
  M.group_empty = opts.renderer.group_empty
end

return M
