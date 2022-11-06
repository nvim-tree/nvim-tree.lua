-- Copyright 2019 Yazdani Kiyan under MIT License
local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"

local M = {}

local function get_user_input_char()
  local c = vim.fn.getchar()
  while type(c) ~= "number" do
    c = vim.fn.getchar()
  end
  return vim.fn.nr2char(c)
end

---Get all windows in the current tabpage that aren't NvimTree.
---@return table with valid win_ids
local function usable_win_ids()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local win_ids = vim.api.nvim_tabpage_list_wins(tabpage)
  local tree_winid = view.get_winnr(tabpage)

  return vim.tbl_filter(function(id)
    local bufid = vim.api.nvim_win_get_buf(id)
    for option, v in pairs(M.window_picker.exclude) do
      local ok, option_value = pcall(vim.api.nvim_buf_get_option, bufid, option)
      if ok and vim.tbl_contains(v, option_value) then
        return false
      end
    end

    local win_config = vim.api.nvim_win_get_config(id)
    return id ~= tree_winid and win_config.focusable and not win_config.external
  end, win_ids)
end

---Find the first window in the tab that is not NvimTree.
---@return integer -1 if none available
local function first_win_id()
  local selectable = usable_win_ids()
  if #selectable > 0 then
    return selectable[1]
  else
    return -1
  end
end

---Get user to pick a window in the tab that is not NvimTree.
---@return integer|nil -- If a valid window was picked, return its id. If an
---       invalid window was picked / user canceled, return nil. If there are
---       no selectable windows, return -1.
local function pick_win_id()
  local selectable = usable_win_ids()

  -- If there are no selectable windows: return. If there's only 1, return it without picking.
  if #selectable == 0 then
    return -1
  end
  if #selectable == 1 then
    return selectable[1]
  end

  local i = 1
  local win_opts = {}
  local win_map = {}
  local laststatus = vim.o.laststatus
  vim.o.laststatus = 2

  local tabpage = vim.api.nvim_get_current_tabpage()
  local win_ids = vim.api.nvim_tabpage_list_wins(tabpage)

  local not_selectable = vim.tbl_filter(function(id)
    return not vim.tbl_contains(selectable, id)
  end, win_ids)

  if laststatus == 3 then
    for _, win_id in ipairs(not_selectable) do
      local ok_status, statusline = pcall(vim.api.nvim_win_get_option, win_id, "statusline")
      local ok_hl, winhl = pcall(vim.api.nvim_win_get_option, win_id, "winhl")

      win_opts[win_id] = {
        statusline = ok_status and statusline or "",
        winhl = ok_hl and winhl or "",
      }

      -- Clear statusline for windows not selectable
      vim.api.nvim_win_set_option(win_id, "statusline", " ")
    end
  end

  -- Setup UI
  for _, id in ipairs(selectable) do
    local char = M.window_picker.chars:sub(i, i)
    local ok_status, statusline = pcall(vim.api.nvim_win_get_option, id, "statusline")
    local ok_hl, winhl = pcall(vim.api.nvim_win_get_option, id, "winhl")

    win_opts[id] = {
      statusline = ok_status and statusline or "",
      winhl = ok_hl and winhl or "",
    }
    win_map[char] = id

    vim.api.nvim_win_set_option(id, "statusline", "%=" .. char .. "%=")
    vim.api.nvim_win_set_option(id, "winhl", "StatusLine:NvimTreeWindowPicker,StatusLineNC:NvimTreeWindowPicker")

    i = i + 1
    if i > #M.window_picker.chars then
      break
    end
  end

  vim.cmd "redraw"
  if vim.opt.cmdheight._value ~= 0 then
    print "Pick window: "
  end
  local _, resp = pcall(get_user_input_char)
  resp = (resp or ""):upper()
  utils.clear_prompt()

  -- Restore window options
  for _, id in ipairs(selectable) do
    for opt, value in pairs(win_opts[id]) do
      vim.api.nvim_win_set_option(id, opt, value)
    end
  end

  if laststatus == 3 then
    for _, id in ipairs(not_selectable) do
      for opt, value in pairs(win_opts[id]) do
        vim.api.nvim_win_set_option(id, opt, value)
      end
    end
  end

  vim.o.laststatus = laststatus

  if not vim.tbl_contains(vim.split(M.window_picker.chars, ""), resp) then
    return
  end

  return win_map[resp]
end

local function open_file_in_tab(filename)
  if M.quit_on_open then
    view.close()
  end
  vim.cmd("tabe " .. vim.fn.fnameescape(filename))
end

local function on_preview(buf_loaded)
  if not buf_loaded then
    vim.bo.bufhidden = "delete"

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = vim.api.nvim_create_augroup("RemoveBufHidden", {}),
      buffer = vim.api.nvim_get_current_buf(),
      callback = function()
        vim.bo.bufhidden = ""
      end,
      once = true,
    })
  end
  view.focus()
end

local function get_target_winid(mode, win_ids)
  local target_winid
  if not M.window_picker.enable or mode == "edit_no_picker" then
    target_winid = lib.target_winid

    -- first available window
    if not vim.tbl_contains(win_ids, target_winid) then
      target_winid = first_win_id()
    end
  else
    -- pick a window
    target_winid = pick_win_id()
    if target_winid == nil then
      -- pick failed/cancelled
      return
    end
  end

  if target_winid == -1 then
    target_winid = lib.target_winid
  end
  return target_winid
end

-- This is only to avoid the BufEnter for nvim-tree to trigger
-- which would cause find-file to run on an invalid file.
local function set_current_win_no_autocmd(winid, autocmd)
  local eventignore = vim.opt.eventignore:get()
  vim.opt.eventignore:append(autocmd)
  vim.api.nvim_set_current_win(winid)
  vim.opt.eventignore = eventignore
end

local function open_in_new_window(filename, mode, win_ids)
  if type(mode) ~= "string" then
    mode = ""
  end

  local target_winid = get_target_winid(mode, win_ids)
  if not target_winid then
    return
  end

  local create_new_window = #vim.api.nvim_list_wins() == 1
  local new_window_side = (view.View.side == "right") and "aboveleft" or "belowright"

  -- Target is invalid or window does not exist in current tabpage: create new window
  if not vim.tbl_contains(win_ids, target_winid) then
    vim.cmd(new_window_side .. " vsplit")
    target_winid = vim.api.nvim_get_current_win()
    lib.target_winid = target_winid

    -- No need to split, as we created a new window.
    create_new_window = false
    if mode:match "split$" then
      mode = "edit"
    end
  elseif not vim.o.hidden then
    -- If `hidden` is not enabled, check if buffer in target window is
    -- modified, and create new split if it is.
    local target_bufid = vim.api.nvim_win_get_buf(target_winid)
    if vim.api.nvim_buf_get_option(target_bufid, "modified") then
      mode = "vsplit"
    end
  end

  local fname = vim.fn.fnameescape(filename)

  local cmd
  if create_new_window then
    cmd = string.format("%s vsplit %s", new_window_side, fname)
  elseif mode:match "split$" then
    cmd = string.format("%s %s", mode, fname)
  else
    cmd = string.format("edit %s", fname)
  end

  if mode == "preview" and view.View.float.enable then
    -- ignore "WinLeave" autocmd on preview
    -- because the registered "WinLeave"
    -- will kill the floating window immediately
    set_current_win_no_autocmd(target_winid, { "WinLeave", "BufEnter" })
  else
    set_current_win_no_autocmd(target_winid, { "BufEnter" })
  end

  pcall(vim.cmd, cmd)
  lib.set_target_win()
end

local function is_already_loaded(filename)
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf_id) and filename == vim.api.nvim_buf_get_name(buf_id) then
      return true
    end
  end
  return false
end

local function edit_in_current_buf(filename)
  require("nvim-tree.view").abandon_current_window()
  vim.cmd("edit " .. vim.fn.fnameescape(filename))
end

function M.fn(mode, filename)
  if type(mode) ~= "string" then
    mode = ""
  end

  if mode == "tabnew" then
    return open_file_in_tab(filename)
  end

  if mode == "edit_in_place" then
    return edit_in_current_buf(filename)
  end

  local tabpage = vim.api.nvim_get_current_tabpage()
  local win_ids = vim.api.nvim_tabpage_list_wins(tabpage)
  local buf_loaded = is_already_loaded(filename)

  local found_win = utils.get_win_buf_from_path(filename)
  if found_win and mode == "preview" then
    return
  end

  if not found_win then
    open_in_new_window(filename, mode, win_ids)
  else
    vim.api.nvim_set_current_win(found_win)
    vim.bo.bufhidden = ""
  end

  if M.resize_window then
    view.resize()
  end

  if mode == "preview" then
    return on_preview(buf_loaded)
  end

  if M.quit_on_open then
    view.close()
  end
end

function M.setup(opts)
  M.quit_on_open = opts.actions.open_file.quit_on_open
  M.resize_window = opts.actions.open_file.resize_window
  if opts.actions.open_file.window_picker.chars then
    opts.actions.open_file.window_picker.chars = tostring(opts.actions.open_file.window_picker.chars):upper()
  end
  M.window_picker = opts.actions.open_file.window_picker
end

return M
