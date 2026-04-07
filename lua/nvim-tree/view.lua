local view_state = require("nvim-tree.view-state")
local events = require("nvim-tree.events")
local utils = require("nvim-tree.utils")
local log = require("nvim-tree.log")
local notify = require("nvim-tree.notify")
local config = require("nvim-tree.config")

---@class OpenInWinOpts
---@field hijack_current_buf boolean|nil default true
---@field resize boolean|nil default true
---@field winid number|nil 0 or nil for current

local M = {}

-- The initial state of a tab
local tabinitial = {
  -- The position of the cursor { line, column }
  cursor = { 0, 0 },
  -- The NvimTree window number
  winnr = nil,
}

local BUFNR_PER_TAB = {}

---@type { name: string, value: any }[]
local BUFFER_OPTIONS = {
  { name = "bufhidden",  value = "wipe" },
  { name = "buflisted",  value = false },
  { name = "buftype",    value = "nofile" },
  { name = "filetype",   value = "NvimTree" },
  { name = "modifiable", value = false },
  { name = "swapfile",   value = false },
}

---@param bufnr integer
---@return boolean
local function matches_bufnr(bufnr)
  for _, b in pairs(BUFNR_PER_TAB) do
    if b == bufnr then
      return true
    end
  end
  return false
end

local function wipe_rogue_buffer()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not matches_bufnr(bufnr) and utils.is_nvim_tree_buf(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

---@param bufnr integer|boolean|nil
local function create_buffer(bufnr)
  wipe_rogue_buffer()

  local tab = vim.api.nvim_get_current_tabpage()
  BUFNR_PER_TAB[tab] = bufnr or vim.api.nvim_create_buf(false, false)

  bufnr = M.get_bufnr()
  for _, option in ipairs(BUFFER_OPTIONS) do
    vim.api.nvim_set_option_value(option.name, option.value, { buf = bufnr })
  end

  vim.api.nvim_buf_set_name(M.get_bufnr(), "NvimTree_" .. tab)

  require("nvim-tree.keymap").on_attach(M.get_bufnr())

  events._dispatch_tree_attached_post(M.get_bufnr())
end

local move_tbl = {
  left = "H",
  right = "L",
}

-- setup_tabpage sets up the initial state of a tab
---@param tabpage integer
local function setup_tabpage(tabpage)
  local winnr = vim.api.nvim_get_current_win()
  view_state.Active.tabpages[tabpage] = vim.tbl_extend("force", view_state.Active.tabpages[tabpage] or tabinitial, { winnr = winnr })
end

local function set_window_options_and_buffer()
  pcall(vim.api.nvim_command, "buffer " .. M.get_bufnr())

  local eventignore = vim.api.nvim_get_option_value("eventignore", {})
  vim.api.nvim_set_option_value("eventignore", "all", {})

  for k, v in pairs(view_state.Active.winopts) do
    vim.api.nvim_set_option_value(k, v, { scope = "local" })
  end

  vim.api.nvim_set_option_value("eventignore", eventignore, {})
end

---@return vim.api.keyset.win_config
local function open_win_config()
  if type(config.g.view.float.open_win_config) == "function" then
    return config.g.view.float.open_win_config()
  else
    return config.g.view.float.open_win_config --[[ @as vim.api.keyset.win_config ]]
  end
end

local function open_window()
  if config.g.view.float.enable then
    vim.api.nvim_open_win(0, true, open_win_config())
  else
    vim.api.nvim_command("vsp")
    M.reposition_window()
  end
  setup_tabpage(vim.api.nvim_get_current_tabpage())
  set_window_options_and_buffer()
end

---@param buf integer
---@return boolean
local function is_buf_displayed(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.fn.buflisted(buf) == 1
end

---@return number|nil
local function get_alt_or_next_buf()
  local alt_buf = vim.fn.bufnr("#")
  if is_buf_displayed(alt_buf) then
    return alt_buf
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_buf_displayed(buf) then
      return buf
    end
  end
end

local function switch_buf_if_last_buf()
  if #vim.api.nvim_list_wins() == 1 then
    local buf = get_alt_or_next_buf()
    if buf then
      vim.cmd("sb" .. buf)
    else
      vim.cmd("new")
    end
  end
end

-- save_tab_state saves any state that should be preserved across redraws.
---@param tabnr integer
local function save_tab_state(tabnr)
  local tabpage = tabnr or vim.api.nvim_get_current_tabpage()
  view_state.Active.cursors[tabpage] = vim.api.nvim_win_get_cursor(M.get_winnr(tabpage) or 0)
end

---@param tabpage integer
local function close(tabpage)
  if not M.is_visible({ tabpage = tabpage }) then
    return
  end
  save_tab_state(tabpage)
  switch_buf_if_last_buf()
  local tree_win = M.get_winnr(tabpage)
  local current_win = vim.api.nvim_get_current_win()
  for _, win in pairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      local prev_win = vim.fn.winnr("#") -- this tab only
      if tree_win == current_win and prev_win > 0 then
        vim.api.nvim_set_current_win(vim.fn.win_getid(prev_win))
      end
      if vim.api.nvim_win_is_valid(tree_win or 0) then
        local success, error = pcall(vim.api.nvim_win_close, tree_win or 0, true)
        if not success then
          notify.debug("Failed to close window: " .. error)
          return
        end
      end
      return
    end
  end
end

function M.close_this_tab_only()
  close(vim.api.nvim_get_current_tabpage())
end

function M.close_all_tabs()
  for tabpage, _ in pairs(view_state.Active.tabpages) do
    close(tabpage)
  end
end

---@param tabpage integer|nil
function M.close(tabpage)
  if config.g.tab.sync.close then
    M.close_all_tabs()
  elseif tabpage then
    close(tabpage)
  else
    M.close_this_tab_only()
  end
end

---@param options table|nil
function M.open(options)
  if M.is_visible() then
    return
  end

  local profile = log.profile_start("view open")

  events._dispatch_on_tree_pre_open()
  create_buffer()
  open_window()
  M.resize()

  local opts = options or { focus_tree = true }
  if not opts.focus_tree then
    vim.cmd("wincmd p")
  end
  events._dispatch_on_tree_open()

  log.profile_end(profile)
end

local function grow()
  local starts_at = (M.is_root_folder_visible(require("nvim-tree.core").get_cwd()) and view_state.Active.root_excluded) and 1 or 0
  local lines = vim.api.nvim_buf_get_lines(M.get_bufnr(), starts_at, -1, false)
  -- number of columns of right-padding to indicate end of path
  local padding = view_state.get_size(view_state.Active.padding)

  -- account for sign/number columns etc.
  local wininfo = vim.fn.getwininfo(M.get_winnr())
  if type(wininfo) == "table" and type(wininfo[1]) == "table" then
    padding = padding + wininfo[1].textoff
  end

  local final_width = view_state.Active.initial_width
  local max_width = view_state.get_width(view_state.Active.max_width)
  if max_width == -1 then
    max_width = math.huge
  end

  local ns_id = vim.api.nvim_get_namespaces()["NvimTreeExtmarks"]
  for i, l in pairs(lines) do
    local line_nr = starts_at + i - 1
    local line_width = vim.fn.strchars(l)
    -- also add space for right-aligned icons
    local extmarks = vim.api.nvim_buf_get_extmarks(M.get_bufnr(), ns_id, { line_nr, 0 }, { line_nr, -1 }, { details = true })
    line_width = line_width + utils.extmarks_length(extmarks) + padding
    final_width = math.max(final_width, line_width)
    if final_width >= max_width then
      final_width = max_width
      break
    end
  end
  M.resize(final_width)
end

function M.grow_from_content()
  if view_state.Active.adaptive_size then
    grow()
  end
end

---@param size string|number|nil
function M.resize(size)
  if config.g.view.float.enable and not view_state.Active.adaptive_size then
    -- if the floating windows's adaptive size is not desired, then the
    -- float size should be defined in view.float.open_win_config
    return
  end

  if type(size) == "string" then
    size = vim.trim(size)
    local first_char = size:sub(1, 1)
    size = tonumber(size)

    if first_char == "+" or first_char == "-" then
      size = view_state.Active.width + size
    end
  end

  if type(size) == "number" and size <= 0 then
    return
  end

  if size then
    view_state.Active.width = size
  end

  if not M.is_visible() then
    return
  end

  local winnr = M.get_winnr() or 0

  local new_size = view_state.get_width()

  if new_size ~= vim.api.nvim_win_get_width(winnr) then
    vim.api.nvim_win_set_width(winnr, new_size)
    if not config.g.view.preserve_window_proportions then
      vim.cmd(":wincmd =")
    end
  end

  events._dispatch_on_tree_resize(new_size)
end

function M.reposition_window()
  local move_to = move_tbl[config.g.view.side]
  vim.api.nvim_command("wincmd " .. move_to)
  M.resize()
end

local function set_current_win()
  local current_tab = vim.api.nvim_get_current_tabpage()
  view_state.Active.tabpages[current_tab].winnr = vim.api.nvim_get_current_win()
end

---Open the tree in the a window
---@param opts OpenInWinOpts|nil
function M.open_in_win(opts)
  opts = opts or { hijack_current_buf = true, resize = true }
  events._dispatch_on_tree_pre_open()
  if opts.winid and vim.api.nvim_win_is_valid(opts.winid) then
    vim.api.nvim_set_current_win(opts.winid)
  end
  create_buffer(opts.hijack_current_buf and vim.api.nvim_get_current_buf())
  setup_tabpage(vim.api.nvim_get_current_tabpage())
  set_current_win()
  set_window_options_and_buffer()
  if opts.resize then
    M.reposition_window()
    M.resize()
  end
  events._dispatch_on_tree_open()
end

function M.abandon_current_window()
  local tab = vim.api.nvim_get_current_tabpage()
  BUFNR_PER_TAB[tab] = nil
  if view_state.Active.tabpages[tab] then
    view_state.Active.tabpages[tab].winnr = nil
  end
end

function M.abandon_all_windows()
  for tab, _ in pairs(vim.api.nvim_list_tabpages()) do
    BUFNR_PER_TAB[tab] = nil
    if view_state.Active.tabpages[tab] then
      view_state.Active.tabpages[tab].winnr = nil
    end
  end
end

---@param opts table|nil
---@return boolean
function M.is_visible(opts)
  if opts and opts.tabpage then
    if view_state.Active.tabpages[opts.tabpage] == nil then
      return false
    end
    local winnr = view_state.Active.tabpages[opts.tabpage].winnr
    return winnr and vim.api.nvim_win_is_valid(winnr)
  end

  if opts and opts.any_tabpage then
    for _, v in pairs(view_state.Active.tabpages) do
      if v.winnr and vim.api.nvim_win_is_valid(v.winnr) then
        return true
      end
    end
    return false
  end

  return M.get_winnr() ~= nil and vim.api.nvim_win_is_valid(M.get_winnr() or 0)
end

---@param opts table|nil
function M.set_cursor(opts)
  if M.is_visible() then
    pcall(vim.api.nvim_win_set_cursor, M.get_winnr(), opts)
  end
end

---@param winnr number|nil
---@param open_if_closed boolean|nil
function M.focus(winnr, open_if_closed)
  local wnr = winnr or M.get_winnr()

  if vim.api.nvim_win_get_tabpage(wnr or 0) ~= vim.api.nvim_win_get_tabpage(0) then
    M.close()
    M.open()
    wnr = M.get_winnr()
  elseif open_if_closed and not M.is_visible() then
    M.open()
  end

  if wnr then
    vim.api.nvim_set_current_win(wnr)
  end
end

--- Retrieve the winid of the open tree.
---@param opts? nvim_tree.api.tree.winid.Opts
---@return number? winid unlike get_winnr(), this returns nil if the nvim-tree window is not visible
function M.winid(opts)
  local tabpage = opts and opts.tabpage
  if tabpage == 0 then
    tabpage = vim.api.nvim_get_current_tabpage()
  end
  if M.is_visible({ tabpage = tabpage }) then
    return M.get_winnr(tabpage)
  else
    return nil
  end
end

--- Restores the state of a NvimTree window if it was initialized before.
function M.restore_tab_state()
  local tabpage = vim.api.nvim_get_current_tabpage()
  M.set_cursor(view_state.Active.cursors[tabpage])
end

--- Returns the window number for nvim-tree within the tabpage specified
---@param tabpage number|nil (optional) the number of the chosen tabpage. Defaults to current tabpage.
---@return number|nil
function M.get_winnr(tabpage)
  tabpage = tabpage or vim.api.nvim_get_current_tabpage()
  local tabinfo = view_state.Active.tabpages[tabpage]
  if tabinfo and tabinfo.winnr and vim.api.nvim_win_is_valid(tabinfo.winnr) then
    return tabinfo.winnr
  end
end

--- Returns the current nvim tree bufnr
---@return number
function M.get_bufnr()
  return BUFNR_PER_TAB[vim.api.nvim_get_current_tabpage()]
end

function M._prevent_buffer_override()
  local view_winnr = M.get_winnr()
  local view_bufnr = M.get_bufnr()

  -- need to schedule to let the new buffer populate the window
  -- because this event needs to be run on bufWipeout.
  -- Otherwise the curwin/curbuf would match the view buffer and the view window.
  vim.schedule(function()
    local curwin = vim.api.nvim_get_current_win()
    local curwinconfig = vim.api.nvim_win_get_config(curwin)
    local curbuf = vim.api.nvim_win_get_buf(curwin)
    local bufname = vim.api.nvim_buf_get_name(curbuf)

    if not bufname:match("NvimTree") then
      for i, tabpage in ipairs(view_state.Active.tabpages) do
        if tabpage.winnr == view_winnr then
          view_state.Active.tabpages[i] = nil
          break
        end
      end
    end
    if curwin ~= view_winnr or bufname == "" or curbuf == view_bufnr then
      return
    end

    -- patch to avoid the overriding window to be fixed in size
    -- might need a better patch
    vim.cmd("setlocal nowinfixwidth")
    vim.cmd("setlocal nowinfixheight")
    M.open({ focus_tree = false })

    local explorer = require("nvim-tree.core").get_explorer()
    if explorer then
      explorer.renderer:draw()
    end

    pcall(vim.api.nvim_win_close, curwin, { force = true })

    -- to handle opening a file using :e when nvim-tree is on floating mode
    -- falling back to the current window instead of creating a new one
    if curwinconfig.relative ~= "" then
      require("nvim-tree.actions.node.open-file").fn("edit_in_place", bufname)
    else
      require("nvim-tree.actions.node.open-file").fn("edit", bufname)
    end
  end)
end

---@param cwd string|nil
---@return boolean
function M.is_root_folder_visible(cwd)
  return cwd ~= "/" and config.g.renderer.root_folder_label ~= false
end

-- used on ColorScheme event
function M.reset_winhl()
  local winnr = M.get_winnr()
  if winnr and vim.api.nvim_win_is_valid(winnr) then
    vim.wo[M.get_winnr()].winhl = view_state.Active.winopts.winhl
  end
end

---Check if width determined or calculated on-fly
---@return boolean
function M.is_width_determined()
  return type(view_state.Active.width) ~= "function"
end

---Called on BufWipeout
---Prevent new opened file from opening in the same window as nvim-tree
function M.wipeout()
  if not utils.is_nvim_tree_buf(0) then
    return
  end
  if config.g.actions.open_file.eject then
    M._prevent_buffer_override()
  else
    M.abandon_current_window()
  end
end

return M
