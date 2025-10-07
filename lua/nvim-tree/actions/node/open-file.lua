-- Copyright 2019 Yazdani Kiyan under MIT License
local lib = require("nvim-tree.lib")
local notify = require("nvim-tree.notify")
local utils = require("nvim-tree.utils")
local full_name = require("nvim-tree.renderer.components.full-name")
local view = require("nvim-tree.view")

local M = {}

---Get single char from user input
---@return string
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
      local ok, option_value
      if vim.fn.has("nvim-0.10") == 1 then
        ok, option_value = pcall(vim.api.nvim_get_option_value, option, { buf = bufid })
      else
        ok, option_value = pcall(vim.api.nvim_buf_get_option, bufid, option) ---@diagnostic disable-line: deprecated
      end

      if ok and vim.tbl_contains(v, option_value) then
        return false
      end
    end

    local win_config = vim.api.nvim_win_get_config(id)
    return id ~= tree_winid
      and id ~= full_name.popup_win
      and win_config.focusable
      and not win_config.hide
      and not win_config.external
      or false
  end, win_ids)
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

  if #M.window_picker.chars < #selectable then
    notify.error(string.format("More windows (%d) than actions.open_file.window_picker.chars (%d).", #selectable, #M.window_picker.chars))
    return nil
  end

  local i = 1
  local win_opts_selectable = {}
  local win_opts_unselectable = {}
  local win_map = {}
  local laststatus = vim.o.laststatus
  vim.o.laststatus = 2
  local fillchars = vim.opt.fillchars:get()
  local stl = fillchars.stl
  local stlnc = fillchars.stlnc
  fillchars.stl = nil
  fillchars.stlnc = nil
  vim.opt.fillchars = fillchars
  fillchars.stl = stl
  fillchars.stlnc = stlnc

  local tabpage = vim.api.nvim_get_current_tabpage()
  local win_ids = vim.api.nvim_tabpage_list_wins(tabpage)

  local not_selectable = vim.tbl_filter(function(id)
    return not vim.tbl_contains(selectable, id)
  end, win_ids)

  if laststatus == 3 then
    for _, win_id in ipairs(not_selectable) do
      local ok_status, statusline

      if vim.fn.has("nvim-0.10") == 1 then
        ok_status, statusline = pcall(vim.api.nvim_get_option_value, "statusline", { win = win_id })
      else
        ok_status, statusline = pcall(vim.api.nvim_win_get_option, win_id, "statusline") ---@diagnostic disable-line: deprecated
      end

      win_opts_unselectable[win_id] = {
        statusline = ok_status and statusline or "",
      }

      -- Clear statusline for windows not selectable
      if vim.fn.has("nvim-0.10") == 1 then
        vim.api.nvim_set_option_value("statusline", " ", { win = win_id })
      else
        vim.api.nvim_win_set_option(win_id, "statusline", " ") ---@diagnostic disable-line: deprecated
      end
    end
  end

  -- Setup UI
  for _, id in ipairs(selectable) do
    local char = M.window_picker.chars:sub(i, i)

    local ok_status, statusline, ok_hl, winhl
    if vim.fn.has("nvim-0.10") == 1 then
      ok_status, statusline = pcall(vim.api.nvim_get_option_value, "statusline", { win = id })
      ok_hl, winhl = pcall(vim.api.nvim_get_option_value, "winhl", { win = id })
    else
      ok_status, statusline = pcall(vim.api.nvim_win_get_option, id, "statusline") ---@diagnostic disable-line: deprecated
      ok_hl, winhl = pcall(vim.api.nvim_win_get_option, id, "winhl") ---@diagnostic disable-line: deprecated
    end

    win_opts_selectable[id] = {
      statusline = ok_status and statusline or "",
      winhl = ok_hl and winhl or "",
    }
    win_map[char] = id

    if vim.fn.has("nvim-0.10") == 1 then
      vim.api.nvim_set_option_value("statusline", "%=" .. char .. "%=",                                                { win = id })
      vim.api.nvim_set_option_value("winhl",      "StatusLine:NvimTreeWindowPicker,StatusLineNC:NvimTreeWindowPicker", { win = id })
    else
      vim.api.nvim_win_set_option(id, "statusline", "%=" .. char .. "%=") ---@diagnostic disable-line: deprecated
      vim.api.nvim_win_set_option(id, "winhl",      "StatusLine:NvimTreeWindowPicker,StatusLineNC:NvimTreeWindowPicker") ---@diagnostic disable-line: deprecated
    end

    i = i + 1
    if i > #M.window_picker.chars then
      break
    end
  end

  vim.cmd("redraw")
  if vim.opt.cmdheight._value ~= 0 then
    print("Pick window: ")
  end
  local _, resp = pcall(get_user_input_char)
  resp = (resp or ""):upper()
  utils.clear_prompt()

  -- Restore window options
  for _, id in ipairs(selectable) do
    for opt, value in pairs(win_opts_selectable[id]) do
      if vim.fn.has("nvim-0.10") == 1 then
        vim.api.nvim_set_option_value(opt, value, { win = id })
      else
        vim.api.nvim_win_set_option(id, opt, value) ---@diagnostic disable-line: deprecated
      end
    end
  end

  if laststatus == 3 then
    for _, id in ipairs(not_selectable) do
      -- Ensure window still exists at this point
      if vim.api.nvim_win_is_valid(id) then
        for opt, value in pairs(win_opts_unselectable[id]) do
          if vim.fn.has("nvim-0.10") == 1 then
            vim.api.nvim_set_option_value(opt, value, { win = id })
          else
            vim.api.nvim_win_set_option(id, opt, value) ---@diagnostic disable-line: deprecated
          end
        end
      end
    end
  end

  vim.o.laststatus = laststatus
  vim.opt.fillchars = fillchars

  if not vim.tbl_contains(vim.split(M.window_picker.chars, ""), resp) then
    return
  end

  return win_map[resp]
end

local function open_file_in_tab(filename)
  if M.quit_on_open then
    view.close()
  end
  if M.relative_path then
    filename = utils.path_relative(filename, vim.fn.getcwd())
  end
  vim.cmd.tabnew()
  vim.bo.bufhidden = "wipe"
  -- Following vim.fn.tabnew the # buffer may be set to the tree buffer. There is no way to clear the # buffer via vim.fn.setreg as it requires a valid buffer. Clear # by setting it to a new temporary scratch buffer.
  if utils.is_nvim_tree_buf(vim.fn.bufnr("#")) then
    local tmpbuf = vim.api.nvim_create_buf(false, true)
    vim.fn.setreg("#", tmpbuf)
    vim.api.nvim_buf_delete(tmpbuf, { force = true })
  end
  vim.cmd.edit(vim.fn.fnameescape(filename))
end

local function drop(filename)
  if M.quit_on_open then
    view.close()
  end
  if M.relative_path then
    filename = utils.path_relative(filename, vim.fn.getcwd())
  end
  vim.cmd("drop " .. vim.fn.fnameescape(filename))
end

local function tab_drop(filename)
  if M.quit_on_open then
    view.close()
  end
  if M.relative_path then
    filename = utils.path_relative(filename, vim.fn.getcwd())
  end
  vim.cmd("tab :drop " .. vim.fn.fnameescape(filename))
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

local function get_target_winid(mode)
  local target_winid
  if not M.window_picker.enable or string.find(mode, "no_picker") then
    target_winid = lib.target_winid
    local usable_wins = usable_win_ids()
    -- first available usable window
    if not vim.tbl_contains(usable_wins, target_winid) then
      if #usable_wins > 0 then
        target_winid = usable_wins[1]
      else
        target_winid = -1
      end
    end
  else
    -- pick a window
    if type(M.window_picker.picker) == "function" then
      target_winid = M.window_picker.picker()
    else
      target_winid = pick_win_id()
    end
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

local function open_in_new_window(filename, mode)
  if type(mode) ~= "string" then
    mode = ""
  end

  local target_winid = get_target_winid(mode)
  if not target_winid then
    return
  end

  local position = string.find(mode, "no_picker")
  if position then
    mode = string.sub(mode, 0, position - 2)
  end

  -- non-floating, non-nvim-tree windows
  local win_ids = vim.tbl_filter(function(id)
    local config = vim.api.nvim_win_get_config(id)
    local bufnr = vim.api.nvim_win_get_buf(id)
    return config and config.relative == "" or utils.is_nvim_tree_buf(bufnr)
  end, vim.api.nvim_list_wins())

  local create_new_window = #win_ids == 1 -- This implies that the nvim-tree window is the only one
  local new_window_side = (view.View.side == "right") and "aboveleft" or "belowright"

  -- Target is invalid: create new window
  if not vim.tbl_contains(win_ids, target_winid) then
    vim.cmd(new_window_side .. " vsplit")
    target_winid = vim.api.nvim_get_current_win()
    lib.target_winid = target_winid

    -- No need to split, as we created a new window.
    create_new_window = false
    if mode:match("split$") then
      mode = "edit"
    end
  elseif not vim.o.hidden then
    -- If `hidden` is not enabled, check if buffer in target window is
    -- modified, and create new split if it is.
    local target_bufid = vim.api.nvim_win_get_buf(target_winid)

    local modified
    if vim.fn.has("nvim-0.10") == 1 then
      modified = vim.api.nvim_get_option_value("modified", { buf = target_bufid })
    else
      modified = vim.api.nvim_buf_get_option(target_bufid, "modified") ---@diagnostic disable-line: deprecated
    end

    if modified then
      if not mode:match("split$") then
        mode = "vsplit"
      end
    end
  end

  if (mode == "preview" or mode == "preview_no_picker") and view.View.float.enable then
    -- ignore "WinLeave" autocmd on preview
    -- because the registered "WinLeave"
    -- will kill the floating window immediately
    set_current_win_no_autocmd(target_winid, { "WinLeave", "BufEnter" })
  else
    set_current_win_no_autocmd(target_winid, { "BufEnter" })
  end

  local fname
  if M.relative_path then
    fname = utils.escape_special_chars(vim.fn.fnameescape(utils.path_relative(filename, vim.fn.getcwd())))
  else
    fname = utils.escape_special_chars(vim.fn.fnameescape(filename))
  end

  local command
  if create_new_window then
    -- generated from vim.api.nvim_parse_cmd("belowright vsplit foo", {})
    command = { cmd = "vsplit", mods = { split = new_window_side }, args = { fname } }
  elseif mode:match("split$") then
    command = { cmd = mode, args = { fname } }
  else
    command = { cmd = "edit", args = { fname } }
  end

  pcall(vim.api.nvim_cmd, command, { output = false })
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
  if M.relative_path then
    filename = utils.path_relative(filename, vim.fn.getcwd())
  end
  vim.cmd("keepalt keepjumps edit " .. vim.fn.fnameescape(filename))
end

---@param mode string
---@param filename string
---@return nil
function M.fn(mode, filename)
  if type(mode) ~= "string" then
    mode = ""
  end

  if mode == "tabnew" then
    return open_file_in_tab(filename)
  end

  if mode == "drop" then
    return drop(filename)
  end

  if mode == "tab_drop" then
    return tab_drop(filename)
  end

  if mode == "edit_in_place" then
    return edit_in_current_buf(filename)
  end

  local buf_loaded = is_already_loaded(filename)

  local found_win = utils.get_win_buf_from_path(filename)
  if found_win and (mode == "preview" or mode == "preview_no_picker") then
    return
  end

  if not found_win then
    open_in_new_window(filename, mode)
  else
    vim.api.nvim_set_current_win(found_win)
    vim.bo.bufhidden = ""
  end

  if M.resize_window then
    view.resize()
  end

  if mode == "preview" or mode == "preview_no_picker" then
    return on_preview(buf_loaded)
  end

  if M.quit_on_open then
    view.close()
  end
end

function M.setup(opts)
  M.quit_on_open = opts.actions.open_file.quit_on_open
  M.resize_window = opts.actions.open_file.resize_window
  M.relative_path = opts.actions.open_file.relative_path
  if opts.actions.open_file.window_picker.chars then
    opts.actions.open_file.window_picker.chars = tostring(opts.actions.open_file.window_picker.chars):upper()
  end
  M.window_picker = opts.actions.open_file.window_picker
end

return M
