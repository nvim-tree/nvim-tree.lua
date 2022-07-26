-- Copyright 2019 Yazdani Kiyan under MIT License
local api = vim.api

local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"

local M = {}

local function get_split_cmd()
  local side = view.View.side
  if side == "right" then
    return "aboveleft"
  end
  if side == "left" then
    return "belowright"
  end
  if side == "top" then
    return "bot"
  end
  return "top"
end

local function get_user_input_char()
  local c = vim.fn.getchar()
  while type(c) ~= "number" do
    c = vim.fn.getchar()
  end
  return vim.fn.nr2char(c)
end

---Get user to pick a window. Selectable windows are all windows in the current
---tabpage that aren't NvimTree.
---@return integer|nil -- If a valid window was picked, return its id. If an
---       invalid window was picked / user canceled, return nil. If there are
---       no selectable windows, return -1.
local function pick_window()
  local tabpage = api.nvim_get_current_tabpage()
  local win_ids = api.nvim_tabpage_list_wins(tabpage)
  local tree_winid = view.get_winnr(tabpage)

  local selectable = vim.tbl_filter(function(id)
    local bufid = api.nvim_win_get_buf(id)
    for option, v in pairs(M.window_picker.exclude) do
      local ok, option_value = pcall(api.nvim_buf_get_option, bufid, option)
      if ok and vim.tbl_contains(v, option_value) then
        return false
      end
    end

    local win_config = api.nvim_win_get_config(id)
    return id ~= tree_winid and win_config.focusable and not win_config.external
  end, win_ids)

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

  local not_selectable = vim.tbl_filter(function(id)
    return not vim.tbl_contains(selectable, id)
  end, win_ids)

  if laststatus == 3 then
    for _, win_id in ipairs(not_selectable) do
      local ok_status, statusline = pcall(api.nvim_win_get_option, win_id, "statusline")
      local ok_hl, winhl = pcall(api.nvim_win_get_option, win_id, "winhl")

      win_opts[win_id] = {
        statusline = ok_status and statusline or "",
        winhl = ok_hl and winhl or "",
      }

      -- Clear statusline for windows not selectable
      api.nvim_win_set_option(win_id, "statusline", " ")
    end
  end

  -- Setup UI
  for _, id in ipairs(selectable) do
    local char = M.window_picker.chars:sub(i, i)
    local ok_status, statusline = pcall(api.nvim_win_get_option, id, "statusline")
    local ok_hl, winhl = pcall(api.nvim_win_get_option, id, "winhl")

    win_opts[id] = {
      statusline = ok_status and statusline or "",
      winhl = ok_hl and winhl or "",
    }
    win_map[char] = id

    api.nvim_win_set_option(id, "statusline", "%=" .. char .. "%=")
    api.nvim_win_set_option(id, "winhl", "StatusLine:NvimTreeWindowPicker,StatusLineNC:NvimTreeWindowPicker")

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
      api.nvim_win_set_option(id, opt, value)
    end
  end

  if laststatus == 3 then
    for _, id in ipairs(not_selectable) do
      for opt, value in pairs(win_opts[id]) do
        api.nvim_win_set_option(id, opt, value)
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

    api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = api.nvim_create_augroup("RemoveBufHidden", {}),
      buffer = api.nvim_get_current_buf(),
      callback = function()
        vim.bo.bufhidden = ""
      end,
      once = true,
    })
  end
  view.focus()
end

local function get_target_winid(mode)
  local target_winid
  if not M.window_picker.enable or mode == "edit_no_picker" then
    target_winid = lib.target_winid
  else
    local pick_window_id = pick_window()
    if pick_window_id == nil then
      return
    end
    target_winid = pick_window_id
  end

  if target_winid == -1 then
    target_winid = lib.target_winid
  end
  return target_winid
end

-- This is only to avoid the BufEnter for nvim-tree to trigger
-- which would cause find-file to run on an invalid file.
local function set_current_win_no_autocmd(winid)
  vim.cmd "set ei=BufEnter"
  api.nvim_set_current_win(winid)
  vim.cmd 'set ei=""'
end

local function open_in_new_window(filename, mode, win_ids)
  local target_winid = get_target_winid(mode)
  if not target_winid then
    return
  end
  local do_split = mode == "split" or mode == "vsplit"
  local vertical = mode ~= "split"

  -- Target is invalid or window does not exist in current tabpage: create new window
  if not target_winid or not vim.tbl_contains(win_ids, target_winid) then
    local split_cmd = get_split_cmd()
    local splitside = view.is_vertical() and "vsp" or "sp"
    vim.cmd(split_cmd .. " " .. splitside)
    target_winid = api.nvim_get_current_win()
    lib.target_winid = target_winid

    -- No need to split, as we created a new window.
    do_split = false
  elseif not vim.o.hidden then
    -- If `hidden` is not enabled, check if buffer in target window is
    -- modified, and create new split if it is.
    local target_bufid = api.nvim_win_get_buf(target_winid)
    if api.nvim_buf_get_option(target_bufid, "modified") then
      do_split = true
    end
  end

  local fname = vim.fn.fnameescape(filename)

  local cmd
  if do_split or #api.nvim_list_wins() == 1 then
    cmd = string.format("%ssplit %s", vertical and "vertical " or "", fname)
  else
    cmd = string.format("edit %s", fname)
  end

  set_current_win_no_autocmd(target_winid)
  pcall(vim.cmd, cmd)
  lib.set_target_win()
end

local function is_already_loaded(filename)
  for _, buf_id in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf_id) and filename == api.nvim_buf_get_name(buf_id) then
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
  if mode == "tabnew" then
    return open_file_in_tab(filename)
  end

  if mode == "edit_in_place" then
    return edit_in_current_buf(filename)
  end

  local tabpage = api.nvim_get_current_tabpage()
  local win_ids = api.nvim_tabpage_list_wins(tabpage)
  local buf_loaded = is_already_loaded(filename)

  local found_win = utils.get_win_buf_from_path(filename)
  if found_win and mode == "preview" then
    return
  end

  if not found_win then
    open_in_new_window(filename, mode, win_ids)
  else
    api.nvim_set_current_win(found_win)
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
  M.quit_on_open = opts.actions.open_file.quit_on_open or opts.view.float.enable
  M.resize_window = opts.actions.open_file.resize_window
  if opts.actions.open_file.window_picker.chars then
    opts.actions.open_file.window_picker.chars = tostring(opts.actions.open_file.window_picker.chars):upper()
  end
  M.window_picker = opts.actions.open_file.window_picker
end

return M
