local appearance = require("nvim-tree.appearance")
local events = require("nvim-tree.events")
local utils = require("nvim-tree.utils")
local log = require("nvim-tree.log")
local notify = require("nvim-tree.notify")
local globals = require("nvim-tree.globals")

local Class = require("nvim-tree.classic")

---@class OpenInWinOpts
---@field hijack_current_buf boolean|nil default true
---@field resize boolean|nil default true
---@field winid number|nil 0 or nil for current

local DEFAULT_MIN_WIDTH = 30
local DEFAULT_MAX_WIDTH = -1
local DEFAULT_PADDING = 1

---@class (exact) View: Class
---@field live_filter table
---@field side string
---@field float table
---@field private explorer Explorer
---@field private adaptive_size boolean
---@field private centralize_selection boolean
---@field private hide_root_folder boolean
---@field private winopts table
---@field private height integer
---@field private preserve_window_proportions boolean
---@field private initial_width integer
---@field private width (fun():integer)|integer|string
---@field private max_width integer
---@field private padding integer
---@field private bufnr_by_tab table<integer, integer> stored per tab until multi-instance is complete
local View = Class:extend()

---@class View
---@overload fun(args: ViewArgs): View

---@class (exact) ViewArgs
---@field explorer Explorer

---@protected
---@param args ViewArgs
function View:new(args)
  args.explorer:log_new("View")

  self.explorer                    = args.explorer
  self.adaptive_size               = false
  self.centralize_selection        = self.explorer.opts.view.centralize_selection
  self.float                       = self.explorer.opts.view.float
  self.height                      = self.explorer.opts.view.height
  self.hide_root_folder            = self.explorer.opts.renderer.root_folder_label == false
  self.preserve_window_proportions = self.explorer.opts.view.preserve_window_proportions
  self.side                        = (self.explorer.opts.view.side == "right") and "right" or "left"
  self.live_filter                 = { prev_focused_node = nil, }
  self.bufnr_by_tab                = {}

  self.winopts                     = {
    relativenumber = self.explorer.opts.view.relativenumber,
    number         = self.explorer.opts.view.number,
    list           = false,
    foldenable     = false,
    winfixwidth    = true,
    winfixheight   = true,
    spell          = false,
    signcolumn     = self.explorer.opts.view.signcolumn,
    foldmethod     = "manual",
    foldcolumn     = "0",
    cursorcolumn   = false,
    cursorline     = self.explorer.opts.view.cursorline,
    cursorlineopt  = "both",
    colorcolumn    = "0",
    wrap           = false,
    winhl          = appearance.WIN_HL,
  }

  self:configure_width(self.explorer.opts.view.width)
  self.initial_width = self:get_width()
end

function View:destroy()
  self.explorer:log_destroy("View")
end

-- The initial state of a tab
local tabinitial = {
  -- The position of the cursor { line, column }
  cursor = { 0, 0 },
  -- The NvimTree window number
  winid = nil,
}

---@type { name: string, value: any }[]
local BUFFER_OPTIONS = {
  { name = "bufhidden",  value = "wipe" },
  { name = "buflisted",  value = false },
  { name = "buftype",    value = "nofile" },
  { name = "filetype",   value = "NvimTree" },
  { name = "modifiable", value = false },
  { name = "swapfile",   value = false },
}

---@private
---@param bufnr integer
---@return boolean
function View:matches_bufnr(bufnr)
  for _, b in pairs(globals.BUFNR_PER_TAB) do
    if b == bufnr then
      return true
    end
  end
  return false
end

---@private
function View:wipe_rogue_buffer()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not self:matches_bufnr(bufnr) and utils.is_nvim_tree_buf(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

---@private
---@param bufnr integer|false|nil
function View:create_buffer(bufnr)
  self:wipe_rogue_buffer()

  local tab = vim.api.nvim_get_current_tabpage()
  globals.BUFNR_PER_TAB[tab] = bufnr or vim.api.nvim_create_buf(false, false)

  if self.explorer.opts.experimental.multi_instance then
    self.bufnr_by_tab[tab] = globals.BUFNR_PER_TAB[tab]
  end

  bufnr = self:get_bufnr("View:create_buffer")

  vim.api.nvim_buf_set_name(bufnr, "NvimTree_" .. tab)

  for _, option in ipairs(BUFFER_OPTIONS) do
    vim.api.nvim_set_option_value(option.name, option.value, { buf = bufnr })
  end

  require("nvim-tree.keymap").on_attach(bufnr)

  events._dispatch_tree_attached_post(bufnr)
end

---@private
---@param size (fun():integer)|integer|string
---@return integer
function View:get_size(size)
  if type(size) == "number" then
    return size
  elseif type(size) == "function" then
    return self:get_size(size())
  end
  local size_as_number = tonumber(size:sub(0, -2))
  local percent_as_decimal = size_as_number / 100
  return math.floor(vim.o.columns * percent_as_decimal)
end

---@param size (fun():integer)|integer|nil
---@return integer
function View:get_width(size)
  if size then
    return self:get_size(size)
  else
    return self:get_size(self.width)
  end
end

local move_tbl = {
  left = "H",
  right = "L",
}

-- setup_tabpage sets up the initial state of a tab
---@private
---@param tabpage integer
---@param callsite string
function View:setup_tabpage(tabpage, callsite)
  local winid = vim.api.nvim_get_current_win()

  if self.explorer.opts.experimental.multi_instance then
    log.line("dev", "View:setup_tabpage(%3s, %-20.20s) w%d %s",
      tabpage,
      callsite,
      winid,
      globals.TABPAGES[tabpage] and vim.inspect(globals.TABPAGES[tabpage], { newline = "" }) or "tabinitial")
  end

  globals.TABPAGES[tabpage] = vim.tbl_extend("force", globals.TABPAGES[tabpage] or tabinitial, { winid = winid })
end

---@private
function View:set_window_options_and_buffer()
  pcall(vim.api.nvim_command, "buffer " .. self:get_bufnr("View:set_window_options_and_buffer"))

  if vim.fn.has("nvim-0.10") == 1 then
    local eventignore = vim.api.nvim_get_option_value("eventignore", {})
    vim.api.nvim_set_option_value("eventignore", "all", {})

    for k, v in pairs(self.winopts) do
      vim.api.nvim_set_option_value(k, v, { scope = "local" })
    end

    vim.api.nvim_set_option_value("eventignore", eventignore, {})
  else
    local eventignore = vim.api.nvim_get_option("eventignore") ---@diagnostic disable-line: deprecated
    vim.api.nvim_set_option("eventignore", "all") ---@diagnostic disable-line: deprecated

    -- #3009 vim.api.nvim_win_set_option does not set local scope without explicit winid.
    -- Revert to opt_local instead of propagating it through for just the 0.10 path.
    for k, v in pairs(self.winopts) do
      vim.opt_local[k] = v
    end

    vim.api.nvim_set_option("eventignore", eventignore) ---@diagnostic disable-line: deprecated
  end
end

---@private
---@return table
function View:open_win_config()
  if type(self.float.open_win_config) == "function" then
    return self.float.open_win_config()
  else
    return self.float.open_win_config
  end
end

---@private
function View:open_window()
  if self.float.enable then
    vim.api.nvim_open_win(0, true, self:open_win_config())
  else
    vim.api.nvim_command("vsp")
    self:reposition_window()
  end
  self:setup_tabpage(vim.api.nvim_get_current_tabpage(), "View:open_window")
  self:set_window_options_and_buffer()
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

---save_tab_state saves any state that should be preserved across redraws.
---@private
---@param tabnr integer
function View:save_tab_state(tabnr)
  local tabpage = tabnr or vim.api.nvim_get_current_tabpage()
  globals.CURSORS[tabpage] = vim.api.nvim_win_get_cursor(self:get_winid(tabpage, "View:save_tab_state") or 0)
end

---@private
---@param tabpage integer
function View:close_internal(tabpage)
  if self.explorer.opts.experimental.multi_instance then
    log.line("dev", "View:close_internal(t%s)", tabpage)
  end
  if not self:is_visible({ tabpage = tabpage }) then
    return
  end
  self:save_tab_state(tabpage)
  switch_buf_if_last_buf()
  local tree_win = self:get_winid(tabpage, "View:close_internal")
  local current_win = vim.api.nvim_get_current_win()
  for _, win in pairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      local prev_win = vim.fn.winnr("#") -- this tab only
      if tree_win == current_win and prev_win > 0 then
        vim.api.nvim_set_current_win(vim.fn.win_getid(prev_win))
      end
      if vim.api.nvim_win_is_valid(tree_win or 0) then
        if self.explorer.opts.experimental.multi_instance then
          log.line("dev", "View:close_internal(t%s) w%s", tabpage, tree_win)
        end
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

function View:close_this_tab_only()
  self:close_internal(vim.api.nvim_get_current_tabpage())
end

function View:close_all_tabs()
  for tabpage, _ in pairs(globals.TABPAGES) do
    self:close_internal(tabpage)
  end
end

---@param tabpage integer|nil
---@param callsite string
function View:close(tabpage, callsite)
  if self.explorer.opts.experimental.multi_instance then
    log.line("dev", "View:close(t%s, %s)", tabpage, callsite)
  end

  if self.explorer.opts.tab.sync.close then
    self:close_all_tabs()
  elseif tabpage then
    self:close_internal(tabpage)
  else
    self:close_this_tab_only()
  end
end

---@param options table|nil
function View:open(options)
  if self:is_visible() then
    return
  end

  local profile = log.profile_start("view open")

  events._dispatch_on_tree_pre_open()
  self:create_buffer()
  self:open_window()
  self:resize()

  local opts = options or { focus_tree = true }
  if not opts.focus_tree then
    vim.cmd("wincmd p")
  end
  events._dispatch_on_tree_open()

  log.profile_end(profile)
end

---@private
function View:grow()
  local starts_at = self:is_root_folder_visible(require("nvim-tree.core").get_cwd()) and 1 or 0
  local lines = vim.api.nvim_buf_get_lines(self:get_bufnr("View:grow1"), starts_at, -1, false)
  -- number of columns of right-padding to indicate end of path
  local padding = self:get_size(self.padding)

  -- account for sign/number columns etc.
  local wininfo = vim.fn.getwininfo(self:get_winid(nil, "View:grow"))
  if type(wininfo) == "table" and type(wininfo[1]) == "table" then
    padding = padding + wininfo[1].textoff
  end

  local resizing_width = self.initial_width - padding
  local max_width

  -- maybe bound max
  if self.max_width == -1 then
    max_width = -1
  else
    max_width = self:get_width(self.max_width) - padding
  end

  local ns_id = vim.api.nvim_get_namespaces()["NvimTreeExtmarks"]
  for line_nr, l in pairs(lines) do
    local count = vim.fn.strchars(l)
    -- also add space for right-aligned icons
    local extmarks = vim.api.nvim_buf_get_extmarks(self:get_bufnr("View:grow2"), ns_id, { line_nr, 0 }, { line_nr, -1 }, { details = true })
    count = count + utils.extmarks_length(extmarks)
    if resizing_width < count then
      resizing_width = count
    end
    if self.adaptive_size and max_width >= 0 and resizing_width >= max_width then
      resizing_width = max_width
      break
    end
  end
  self:resize(resizing_width + padding)
end

function View:grow_from_content()
  if self.adaptive_size then
    self:grow()
  end
end

---@param size string|number|nil
function View:resize(size)
  if self.float.enable and not self.adaptive_size then
    -- if the floating windows's adaptive size is not desired, then the
    -- float size should be defined in view.float.open_win_config
    return
  end

  if type(size) == "string" then
    size = vim.trim(size)
    local first_char = size:sub(1, 1)
    size = tonumber(size)

    if first_char == "+" or first_char == "-" then
      size = self.width + size
    end
  end

  if type(size) == "number" and size <= 0 then
    return
  end

  if size then
    self.width = size
    self.height = size
  end

  if not self:is_visible() then
    return
  end

  local winid = self:get_winid(nil, "View:resize") or 0

  local new_size = self:get_width()

  if new_size ~= vim.api.nvim_win_get_width(winid) then
    vim.api.nvim_win_set_width(winid, new_size)
    if not self.preserve_window_proportions then
      vim.cmd(":wincmd =")
    end
  end

  events._dispatch_on_tree_resize(new_size)
end

---@private
function View:reposition_window()
  local move_to = move_tbl[self.side]
  vim.api.nvim_command("wincmd " .. move_to)
  self:resize()
end

---@private
---@param callsite string
function View:set_current_win(callsite)
  local current_tab = vim.api.nvim_get_current_tabpage()
  local current_win = vim.api.nvim_get_current_win()

  if self.explorer.opts.experimental.multi_instance then
    log.line("dev", "View:set_current_win(%-20.20s) t%d w%3s->w%3s %s",
      callsite,
      current_tab,
      globals.TABPAGES[current_tab].winid,
      current_win,
      (globals.TABPAGES[current_tab].winid == current_win) and "" or "MISMATCH"
    )
  end

  globals.TABPAGES[current_tab].winid = current_win
end

---Open the tree in the a window
---@param opts OpenInWinOpts|nil
function View:open_in_win(opts)
  opts = opts or { hijack_current_buf = true, resize = true }
  events._dispatch_on_tree_pre_open()
  if opts.winid and vim.api.nvim_win_is_valid(opts.winid) then
    vim.api.nvim_set_current_win(opts.winid)
  end
  self:create_buffer(opts.hijack_current_buf and vim.api.nvim_get_current_buf())
  self:setup_tabpage(vim.api.nvim_get_current_tabpage(),                         "View:open_in_win")
  self:set_current_win("View:open_in_win")
  self:set_window_options_and_buffer()
  if opts.resize then
    self:reposition_window()
    self:resize()
  end
  events._dispatch_on_tree_open()
end

function View:abandon_current_window()
  local tab = vim.api.nvim_get_current_tabpage()

  if self.explorer.opts.experimental.multi_instance then
    log.line("dev", "View:abandon_current_window() t%d w%s b%s member b%s %s",
      tab,
      globals.TABPAGES[tab] and globals.TABPAGES[tab].winid or nil,
      globals.BUFNR_PER_TAB[tab],
      self.bufnr_by_tab[tab],
      (globals.BUFNR_PER_TAB[tab] == self.bufnr_by_tab[tab]) and "" or "MISMATCH")

    self.bufnr_by_tab[tab] = nil
  end

  -- TODO multi-instance kill the buffer instead of retaining

  globals.BUFNR_PER_TAB[tab] = nil
  if globals.TABPAGES[tab] then
    globals.TABPAGES[tab].winid = nil
  end
end

---@param callsite string
function View:abandon_all_windows(callsite)
  for tab, _ in pairs(vim.api.nvim_list_tabpages()) do
    if self.explorer.opts.experimental.multi_instance then
      log.line("dev", "View:abandon_all_windows(%-20.20s) t%d w%s b%s member b%s %s",
        callsite,
        tab,
        globals.TABPAGES and globals.TABPAGES.winid or nil,
        globals.BUFNR_PER_TAB[tab],
        self.bufnr_by_tab[tab],
        (globals.BUFNR_PER_TAB[tab] == self.bufnr_by_tab[tab]) and "" or "MISMATCH")
    end

    -- TODO multi-instance kill the buffer instead of retaining

    globals.BUFNR_PER_TAB[tab] = nil
    if globals.TABPAGES[tab] then
      globals.TABPAGES[tab].winid = nil
    end
  end
end

---@param opts table|nil
---@return boolean
function View:is_visible(opts)
  if opts and opts.tabpage then
    if globals.TABPAGES[opts.tabpage] == nil then
      return false
    end
    local winid = globals.TABPAGES[opts.tabpage].winid
    return winid and vim.api.nvim_win_is_valid(winid)
  end

  if opts and opts.any_tabpage then
    for _, v in pairs(globals.TABPAGES) do
      if v.winid and vim.api.nvim_win_is_valid(v.winid) then
        return true
      end
    end
    return false
  end

  local winid = self:get_winid(nil, "View:is_visible")
  return winid ~= nil and vim.api.nvim_win_is_valid(winid or 0)
end

---@param opts table|nil
function View:set_cursor(opts)
  if self:is_visible() then
    pcall(vim.api.nvim_win_set_cursor, self:get_winid(nil, "View:set_cursor"), opts)
  end
end

---@param winid number|nil
---@param open_if_closed boolean|nil
function View:focus(winid, open_if_closed)
  local wnr = winid or self:get_winid(nil, "View:focus1")

  if vim.api.nvim_win_get_tabpage(wnr or 0) ~= vim.api.nvim_win_get_tabpage(0) then
    self:close(nil, "View:focus")
    self:open()
    wnr = self:get_winid(nil, "View:focus2")
  elseif open_if_closed and not self:is_visible() then
    self:open()
  end

  if wnr then
    vim.api.nvim_set_current_win(wnr)
  end
end

--- Retrieve the winid of the open tree.
---@param opts ApiTreeWinIdOpts|nil
---@return number|nil winid unlike get_winid(), this returns nil if the nvim-tree window is not visible
function View:api_winid(opts)
  local tabpage = opts and opts.tabpage
  if tabpage == 0 then
    tabpage = vim.api.nvim_get_current_tabpage()
  end
  if self:is_visible({ tabpage = tabpage }) then
    return self:get_winid(tabpage, "View:winid")
  else
    return nil
  end
end

--- Restores the state of a NvimTree window if it was initialized before.
function View:restore_tab_state()
  local tabpage = vim.api.nvim_get_current_tabpage()
  self:set_cursor(globals.CURSORS[tabpage])
end

--- winid containing the buffer
---@param tabpage number|nil (optional) the number of the chosen tabpage. Defaults to current tabpage.
---@param callsite string
---@return integer? winid
function View:winid(tabpage, callsite)
  local bufnr = self.bufnr_by_tab[tabpage]

  local msg = string.format("View:winid(%3s, %-20.20s)", tabpage, callsite)

  if bufnr then
    for _, w in pairs(vim.api.nvim_tabpage_list_wins(tabpage or 0)) do
      if vim.api.nvim_win_get_buf(w) == bufnr then
        log.line("dev", "%s b%d : w%s", msg, bufnr, w)
        return w
      end
    end
  else
    log.line("dev", "%s no bufnr", msg)
  end
end

--- Returns the window number for nvim-tree within the tabpage specified
---@param tabpage number|nil (optional) the number of the chosen tabpage. Defaults to current tabpage.
---@param callsite string
---@return number|nil
function View:get_winid(tabpage, callsite)
  local tabid = tabpage or vim.api.nvim_get_current_tabpage()
  local tabinfo = globals.TABPAGES[tabid]
  local tabinfo_winid = nil

  if self.explorer.opts.experimental.multi_instance then
    local msg_fault = ""
    if not tabinfo then
      msg_fault = "no tabinfo"
    elseif not tabinfo.winid then
      msg_fault = "no tabinfo.winid"
    elseif not vim.api.nvim_win_is_valid(tabinfo.winid) then
      msg_fault = string.format("invalid tabinfo.winid %d", tabinfo.winid)
    else
      tabinfo_winid = tabinfo.winid
    end

    local winid = self:winid(tabid, "View:get_winid")

    if winid ~= tabinfo_winid then
      msg_fault = "MISMATCH"
    end

    local msg = string.format("View:get_winid(%3s, %-20.20s) globals.TABPAGES[%s].winid=w%s view.winid(%s)=w%s %s",
      tabpage,
      callsite,
      tabid, tabinfo_winid,
      tabid, winid,
      msg_fault
    )

    log.line("dev", "%s", msg)

    if winid ~= tabinfo_winid then
      notify.error(msg)
    end
  end

  -- legacy codepath
  if tabinfo and tabinfo.winid and vim.api.nvim_win_is_valid(tabinfo.winid) then
    return tabinfo.winid
  end
end

--- Returns the current nvim tree bufnr
---@param callsite string
---@return number
function View:get_bufnr(callsite)
  local tab = vim.api.nvim_get_current_tabpage()
  if self.explorer.opts.experimental.multi_instance then
    local msg = string.format("View:get_bufnr(%-20.20s) globals.BUFNR_PER_TAB[%s]=b%s view.bufnr_by_tab[%s]=b%s MISMATCH",
      callsite,
      tab, globals.BUFNR_PER_TAB[tab],
      tab, self.bufnr_by_tab[tab],
      (globals.BUFNR_PER_TAB[tab] == self.bufnr_by_tab[tab]) and "" or "MISMATCH"
    )

    if globals.BUFNR_PER_TAB[tab] ~= self.bufnr_by_tab[tab] then
      notify.error(msg)
    end

    log.line("dev", msg)
  end
  return globals.BUFNR_PER_TAB[tab]
end

function View:prevent_buffer_override()
  local view_winid = self:get_winid(nil, "View:prevent_buffer_override")
  local view_bufnr = self:get_bufnr("View:prevent_buffer_override")

  -- need to schedule to let the new buffer populate the window
  -- because this event needs to be run on bufWipeout.
  -- Otherwise the curwin/curbuf would match the view buffer and the view window.
  vim.schedule(function()
    local curwin = vim.api.nvim_get_current_win()
    local curwinconfig = vim.api.nvim_win_get_config(curwin)
    local curbuf = vim.api.nvim_win_get_buf(curwin)
    local bufname = vim.api.nvim_buf_get_name(curbuf)

    if not bufname:match("NvimTree") then
      for i, tabpage in ipairs(globals.TABPAGES) do
        if tabpage.winid == view_winid then
          if self.explorer.opts.experimental.multi_instance then
            log.line("dev", "View:prevent_buffer_override() t%d w%d clearing", i, view_winid)
          end

          globals.TABPAGES[i] = nil
          break
        end
      end
    end
    if curwin ~= view_winid or bufname == "" or curbuf == view_bufnr then
      return
    end

    -- patch to avoid the overriding window to be fixed in size
    -- might need a better patch
    vim.cmd("setlocal nowinfixwidth")
    vim.cmd("setlocal nowinfixheight")
    self:open({ focus_tree = false })

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
function View:is_root_folder_visible(cwd)
  return cwd ~= "/" and not self.hide_root_folder
end

-- used on ColorScheme event
function View:reset_winhl()
  local winid = self:get_winid(nil, "View:reset_winhl1")
  if winid and vim.api.nvim_win_is_valid(winid) then
    vim.wo[winid].winhl = appearance.WIN_HL
  end
end

---Check if width determined or calculated on-fly
---@return boolean
function View:is_width_determined()
  return type(self.width) ~= "function"
end

---Configure width-related config
---@param width string|function|number|table|nil
function View:configure_width(width)
  if type(width) == "table" then
    self.adaptive_size = true
    self.width = width.min or DEFAULT_MIN_WIDTH
    self.max_width = width.max or DEFAULT_MAX_WIDTH
    self.padding = width.padding or DEFAULT_PADDING
  elseif width == nil then
    if self.explorer.opts.view.width ~= nil then
      -- if we had input config - fallback to it
      self:configure_width(self.explorer.opts.view.width)
    else
      -- otherwise - restore initial width
      self.width = self.initial_width
    end
  else
    self.adaptive_size = false
    self.width = width
  end
end

return View
