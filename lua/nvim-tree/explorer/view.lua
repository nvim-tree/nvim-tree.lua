local events = require "nvim-tree.events"
local utils = require "nvim-tree.utils"
local log = require "nvim-tree.log"

local ExplorerView = {}

local DEFAULT_MIN_WIDTH = 30
local DEFAULT_MAX_WIDTH = -1
local DEFAULT_PADDING = 1

function ExplorerView:new(opts)
  local o = {
    View = {
      adaptive_size = false,
      centralize_selection = false,
      tabpages = {},
      cursors = {},
      hide_root_folder = false,
      live_filter = {
        prev_focused_node = nil,
      },
      winopts = {
        relativenumber = false,
        number = false,
        list = false,
        foldenable = false,
        winfixwidth = true,
        winfixheight = true,
        spell = false,
        signcolumn = "yes",
        foldmethod = "manual",
        foldcolumn = "0",
        cursorcolumn = false,
        cursorline = true,
        cursorlineopt = "both",
        colorcolumn = "0",
        wrap = false,
        winhl = table.concat({
          "EndOfBuffer:NvimTreeEndOfBuffer",
          "CursorLine:NvimTreeCursorLine",
          "CursorLineNr:NvimTreeCursorLineNr",
          "LineNr:NvimTreeLineNr",
          "WinSeparator:NvimTreeWinSeparator",
          "StatusLine:NvimTreeStatusLine",
          "StatusLineNC:NvimTreeStatuslineNC",
          "SignColumn:NvimTreeSignColumn",
          "Normal:NvimTreeNormal",
          "NormalNC:NvimTreeNormalNC",
          "NormalFloat:NvimTreeNormalFloat",
        }, ","),
      },
    }
  }
  local options = opts.view or {}
  o.View.centralize_selection = options.centralize_selection
  o.View.side = (options.side == "right") and "right" or "left"
  o.View.height = options.height
  o.View.hide_root_folder = opts.renderer.root_folder_label == false
  o.View.tab = opts.tab
  o.View.preserve_window_proportions = options.preserve_window_proportions
  o.View.winopts.cursorline = options.cursorline
  o.View.winopts.number = options.number
  o.View.winopts.relativenumber = options.relativenumber
  o.View.winopts.signcolumn = options.signcolumn
  o.View.float = options.float
  o.on_attach = opts.on_attach

  o.config = vim.deepcopy(options)
  setmetatable(o, self)
  self.__index = self

  o:configure_width(options.width)

  o.View.initial_width = o:get_width()
end

-- The initial state of a tab
local tabinitial = {
  -- The position of the cursor { line, column }
  cursor = { 0, 0 },
  -- The NvimTree window number
  winnr = nil,
}

local BUFNR_PER_TAB = {}
local BUFFER_OPTIONS = {
  swapfile = false,
  buftype = "nofile",
  modifiable = false,
  filetype = "NvimTree",
  bufhidden = "wipe",
  buflisted = false,
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
local function create_buffer(self, bufnr)
  wipe_rogue_buffer()

  local tab = vim.api.nvim_get_current_tabpage()
  BUFNR_PER_TAB[tab] = bufnr or vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(self:get_bufnr(), "NvimTree_" .. tab)

  for option, value in pairs(BUFFER_OPTIONS) do
    vim.bo[self:get_bufnr()][option] = value
  end

  require("nvim-tree.keymap").on_attach(self:get_bufnr())

  events._dispatch_tree_attached_post(self:get_bufnr())
end

---@param size (fun():integer)|integer|string
---@return integer
local function get_size(size)
  if type(size) == "number" then
    return size
  elseif type(size) == "function" then
    return size()
  end
  local size_as_number = tonumber(size:sub(0, -2))
  local percent_as_decimal = size_as_number / 100
  return math.floor(vim.o.columns * percent_as_decimal)
end

---@param size (fun():integer)|integer|nil
function ExplorerView:get_width(size)
  if size then
    return get_size(size)
  else
    return get_size(self.View.width)
  end
end

local move_tbl = {
  left = "H",
  right = "L",
}

-- setup_tabpage sets up the initial state of a tab
---@param tabpage integer
local function setup_tabpage(self, tabpage)
  local winnr = vim.api.nvim_get_current_win()
  self.View.tabpages[tabpage] = vim.tbl_extend("force", self.View.tabpages[tabpage] or tabinitial, { winnr = winnr })
end

local function set_window_options_and_buffer(self)
  pcall(vim.api.nvim_command, "buffer " .. self:get_bufnr())
  local eventignore = vim.opt.eventignore:get()
  vim.opt.eventignore = "all"
  for k, v in pairs(self.View.winopts) do
    vim.opt_local[k] = v
  end
  vim.opt.eventignore = eventignore
end

---@return table
local function open_win_config(self)
  if type(self.View.float.open_win_config) == "function" then
    return self.View.float.open_win_config(self)
  else
    return self.View.float.open_win_config
  end
end

local function open_window(self)
  if self.View.float.enable then
    vim.api.nvim_open_win(0, true, open_win_config(self))
  else
    vim.api.nvim_command "vsp"
    self:reposition_window()
  end
  setup_tabpage(self, vim.api.nvim_get_current_tabpage())
  set_window_options_and_buffer(self)
end

---@param buf integer
---@return boolean
local function is_buf_displayed(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.fn.buflisted(buf) == 1
end

---@return number|nil
local function get_alt_or_next_buf()
  local alt_buf = vim.fn.bufnr "#"
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
      vim.cmd "new"
    end
  end
end

-- save_tab_state saves any state that should be preserved across redraws.
---@param tabnr integer
local function save_tab_state(self, tabnr)
  local tabpage = tabnr or vim.api.nvim_get_current_tabpage()
  self.View.cursors[tabpage] = vim.api.nvim_win_get_cursor(self:get_winnr(tabpage) or 0)
end

---@param tabpage integer
local function close(self, tabpage)
  if not self:is_visible { tabpage = tabpage } then
    return
  end
  save_tab_state(self, tabpage)
  switch_buf_if_last_buf()
  local tree_win = self:get_winnr(tabpage)
  local current_win = vim.api.nvim_get_current_win()
  for _, win in pairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      local prev_win = vim.fn.winnr "#" -- this tab only
      if tree_win == current_win and prev_win > 0 then
        vim.api.nvim_set_current_win(vim.fn.win_getid(prev_win))
      end
      if vim.api.nvim_win_is_valid(tree_win or 0) then
        vim.api.nvim_win_close(tree_win or 0, true)
      end
      events._dispatch_on_tree_close()
      return
    end
  end
end

function ExplorerView:close_this_tab_only()
  close(self, vim.api.nvim_get_current_tabpage())
end

function ExplorerView:close_all_tabs()
  for tabpage, _ in pairs(self.View.tabpages) do
    close(self, tabpage)
  end
end

function ExplorerView:close()
  if self.View.tab.sync.close then
    self:close_all_tabs()
  else
    self:close_this_tab_only()
  end
end

---@param options table|nil
function ExplorerView:open(options)
  if self:is_visible() then
    return
  end

  local profile = log.profile_start "view open"

  create_buffer(self)
  open_window(self)
  self:resize()

  local opts = options or { focus_tree = true }
  if not opts.focus_tree then
    vim.cmd "wincmd p"
  end
  events._dispatch_on_tree_open()

  log.profile_end(profile)
end

local function grow(self)
  local starts_at = self:is_root_folder_visible(require("nvim-tree.core").get_cwd()) and 1 or 0
  local lines = vim.api.nvim_buf_get_lines(self:get_bufnr(), starts_at, -1, false)
  -- number of columns of right-padding to indicate end of path
  local padding = get_size(self.View.padding)

  -- account for sign/number columns etc.
  local wininfo = vim.fn.getwininfo(self:get_winnr())
  if type(wininfo) == "table" and type(wininfo[1]) == "table" then
    padding = padding + wininfo[1].textoff
  end

  local resizing_width = self.View.initial_width - padding
  local max_width

  -- maybe bound max
  if self.View.max_width == -1 then
    max_width = -1
  else
    max_width = self:get_width(self.View.max_width) - padding
  end

  for _, l in pairs(lines) do
    local count = vim.fn.strchars(l)
    if resizing_width < count then
      resizing_width = count
    end
    if self.View.adaptive_size and max_width >= 0 and resizing_width >= max_width then
      resizing_width = max_width
      break
    end
  end
  self:resize(resizing_width + padding)
end

function ExplorerView:grow_from_content()
  if self.View.adaptive_size then
    grow(self)
  end
end

---@param size string|number|nil
function ExplorerView:resize(size)
  if self.View.float.enable and not self.View.adaptive_size then
    -- if the floating windows's adaptive size is not desired, then the
    -- float size should be defined in view.float.open_win_config
    return
  end

  if type(size) == "string" then
    size = vim.trim(size)
    local first_char = size:sub(1, 1)
    size = tonumber(size)

    if first_char == "+" or first_char == "-" then
      size = self.View.width + size
    end
  end

  if type(size) == "number" and size <= 0 then
    return
  end

  if size then
    self.View.width = size
    self.View.height = size
  end

  if not self:is_visible() then
    return
  end

  local new_size = self:get_width()
  vim.api.nvim_win_set_width(self:get_winnr() or 0, new_size)

  events._dispatch_on_tree_resize(new_size)

  if not self.View.preserve_window_proportions then
    vim.cmd ":wincmd ="
  end
end

function ExplorerView:reposition_window()
  local move_to = move_tbl[self.View.side]
  vim.api.nvim_command("wincmd " .. move_to)
  self:resize()
end

local function set_current_win(self)
  local current_tab = vim.api.nvim_get_current_tabpage()
  self.View.tabpages[current_tab].winnr = vim.api.nvim_get_current_win()
end

---Open the tree in the a window
---@param opts OpenInWinOpts|nil
function ExplorerView:open_in_win(opts)
  opts = opts or { hijack_current_buf = true, resize = true }
  if opts.winid and vim.api.nvim_win_is_valid(opts.winid) then
    vim.api.nvim_set_current_win(opts.winid)
  end
  create_buffer(self, opts.hijack_current_buf and vim.api.nvim_get_current_buf())
  setup_tabpage(self, vim.api.nvim_get_current_tabpage())
  set_current_win(self)
  set_window_options_and_buffer(self)
  if opts.resize then
    self:reposition_window()
    self:resize()
  end
end

function ExplorerView:abandon_current_window()
  local tab = vim.api.nvim_get_current_tabpage()
  BUFNR_PER_TAB[tab] = nil
  if self.View.tabpages[tab] then
    self.View.tabpages[tab].winnr = nil
  end
end

function ExplorerView:abandon_all_windows()
  for tab, _ in pairs(vim.api.nvim_list_tabpages()) do
    BUFNR_PER_TAB[tab] = nil
    if self.View.tabpages[tab] then
      self.View.tabpages[tab].winnr = nil
    end
  end
end

---@param opts table|nil
function ExplorerView:is_visible(opts)
  if opts and opts.tabpage then
    if self.View.tabpages[opts.tabpage] == nil then
      return false
    end
    local winnr = self.View.tabpages[opts.tabpage].winnr
    return winnr and vim.api.nvim_win_is_valid(winnr)
  end

  if opts and opts.any_tabpage then
    for _, v in pairs(self.View.tabpages) do
      if v.winnr and vim.api.nvim_win_is_valid(v.winnr) then
        return true
      end
    end
    return false
  end

  return self:get_winnr() ~= nil and vim.api.nvim_win_is_valid(self:get_winnr() or 0)
end

---@param opts table|nil
function ExplorerView:set_cursor(opts)
  if self:is_visible() then
    pcall(vim.api.nvim_win_set_cursor, self:get_winnr(), opts)
  end
end

---@param winnr number|nil
---@param open_if_closed boolean|nil
function ExplorerView:focus(winnr, open_if_closed)
  local wnr = winnr or self:get_winnr()

  if vim.api.nvim_win_get_tabpage(wnr or 0) ~= vim.api.nvim_win_get_tabpage(0) then
    self:close()
    self:open()
    wnr = self:get_winnr()
  elseif open_if_closed and not self:is_visible() then
    self:open()
  end

  if wnr then
    vim.api.nvim_set_current_win(wnr)
  end
end

--- Retrieve the winid of the open tree.
---@param opts ApiTreeWinIdOpts|nil
---@return number|nil winid unlike get_winnr(), this returns nil if the nvim-tree window is not visible
function ExplorerView:winid(opts)
  local tabpage = opts and opts.tabpage
  if tabpage == 0 then
    tabpage = vim.api.nvim_get_current_tabpage()
  end
  if self:is_visible { tabpage = tabpage } then
    return self:get_winnr(tabpage)
  else
    return nil
  end
end

--- Restores the state of a NvimTree window if it was initialized before.
function ExplorerView:restore_tab_state()
  local tabpage = vim.api.nvim_get_current_tabpage()
  self:set_cursor(self.View.cursors[tabpage])
end

--- Returns the window number for nvim-tree within the tabpage specified
---@param tabpage number|nil (optional) the number of the chosen tabpage. Defaults to current tabpage.
---@return number|nil
function ExplorerView:get_winnr(tabpage)
  tabpage = tabpage or vim.api.nvim_get_current_tabpage()
  local tabinfo = self.View.tabpages[tabpage]
  if tabinfo and tabinfo.winnr and vim.api.nvim_win_is_valid(tabinfo.winnr) then
    return tabinfo.winnr
  end
end

--- Returns the current nvim tree bufnr
---@return number
function ExplorerView:get_bufnr()
  return BUFNR_PER_TAB[vim.api.nvim_get_current_tabpage()]
end

---@param bufnr number
---@return boolean
function ExplorerView:is_buf_valid(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

function ExplorerView:_prevent_buffer_override()
  local view_winnr = self:get_winnr()
  local view_bufnr = self:get_bufnr()

  -- need to schedule to let the new buffer populate the window
  -- because this event needs to be run on bufWipeout.
  -- Otherwise the curwin/curbuf would match the view buffer and the view window.
  vim.schedule(function()
    local curwin = vim.api.nvim_get_current_win()
    local curwinconfig = vim.api.nvim_win_get_config(curwin)
    local curbuf = vim.api.nvim_win_get_buf(curwin)
    local bufname = vim.api.nvim_buf_get_name(curbuf)

    if not bufname:match "NvimTree" then
      for i, tabpage in ipairs(self.View.tabpages) do
        if tabpage.winnr == view_winnr then
          M.View.tabpages[i] = nil
          break
        end
      end
    end
    if curwin ~= view_winnr or bufname == "" or curbuf == view_bufnr then
      return
    end

    -- patch to avoid the overriding window to be fixed in size
    -- might need a better patch
    vim.cmd "setlocal nowinfixwidth"
    vim.cmd "setlocal nowinfixheight"
    M.open { focus_tree = false }
    require("nvim-tree.renderer").draw()
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
function ExplorerView:is_root_folder_visible(cwd)
  return cwd ~= "/" and not self.View.hide_root_folder
end

-- used on ColorScheme event
function ExplorerView:reset_winhl()
  local winnr = self:get_winnr()
  if winnr and vim.api.nvim_win_is_valid(winnr) then
    vim.wo[self:get_winnr()].winhl = self.View.winopts.winhl
  end
end

---Check if width determined or calculated on-fly
---@return boolean
function ExplorerView:is_width_determined()
  return type(self.View.width) ~= "function"
end

---Configure width-related config
---@param width string|function|number|table|nil
function ExplorerView:configure_width(width)
  if type(width) == "table" then
    self.View.adaptive_size = true
    self.View.width = width.min or DEFAULT_MIN_WIDTH
    self.View.max_width = width.max or DEFAULT_MAX_WIDTH
    self.View.padding = width.padding or DEFAULT_PADDING
  elseif width == nil then
    if self.config.width ~= nil then
      -- if we had input config - fallback to it
      self.configure_width(self.config.width)
    else
      -- otherwise - restore initial width
      self.View.width = self.View.initial_width
    end
  else
    self.View.adaptive_size = false
    self.View.width = width
  end
end

return ExplorerView
