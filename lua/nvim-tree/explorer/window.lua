local appearance = require("nvim-tree.appearance")
local events = require("nvim-tree.events")
local utils = require("nvim-tree.utils")
local log = require("nvim-tree.log")
local notify = require("nvim-tree.notify")
local view = require("nvim-tree.view")

local Class = require("nvim-tree.classic")

---@class OpenInWinOpts
---@field hijack_current_buf boolean|nil default true
---@field resize boolean|nil default true
---@field winid number|nil 0 or nil for current

local DEFAULT_MIN_WIDTH = 30
local DEFAULT_MAX_WIDTH = -1
local DEFAULT_PADDING = 1

---@class (exact) Window: Class
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
local Window = Class:extend()

---@class Window
---@overload fun(args: WindowArgs): Window

---@class (exact) WindowArgs
---@field explorer Explorer

---@protected
---@param args WindowArgs
function Window:new(args)
  args.explorer:log_new("Window")

  self.explorer                    = args.explorer
  self.adaptive_size               = false
  self.centralize_selection        = self.explorer.opts.view.centralize_selection
  self.float                       = self.explorer.opts.view.float
  self.height                      = self.explorer.opts.view.height
  self.hide_root_folder            = self.explorer.opts.renderer.root_folder_label == false
  self.preserve_window_proportions = self.explorer.opts.view.preserve_window_proportions
  self.side                        = (self.explorer.opts.view.side == "right") and "right" or "left"
  self.live_filter                 = { prev_focused_node = nil, }

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

function Window:destroy()
  self.explorer:log_destroy("Window")
end

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
---@param bufnr integer|false|nil
function Window:create_buffer(bufnr)
  view.wipe_rogue_buffer()

  local tab = view.create_buffer(bufnr)

  vim.api.nvim_buf_set_name(view.get_bufnr(), "NvimTree_" .. tab)

  bufnr = view.get_bufnr()
  for _, option in ipairs(BUFFER_OPTIONS) do
    vim.api.nvim_set_option_value(option.name, option.value, { buf = bufnr })
  end

  require("nvim-tree.keymap").on_attach(view.get_bufnr())

  events._dispatch_tree_attached_post(view.get_bufnr())
end

---@private
---@param size (fun():integer)|integer|string
---@return integer
function Window:get_size(size)
  if type(size) == "number" then
    return size
  elseif type(size) == "function" then
    return self:get_size(size())
  end
  local size_as_number = tonumber(size:sub(0, -2))
  local percent_as_decimal = size_as_number / 100
  return math.floor(vim.o.columns * percent_as_decimal)
end

---@private
---@param size (fun():integer)|integer|nil
---@return integer
function Window:get_width(size)
  if size then
    return self:get_size(size)
  else
    return self:get_size(self.width)
  end
end

---@private
function Window:set_window_options_and_buffer()
  pcall(vim.api.nvim_command, "buffer " .. view.get_bufnr())

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
function Window:open_win_config()
  if type(self.float.open_win_config) == "function" then
    return self.float.open_win_config()
  else
    return self.float.open_win_config
  end
end

---@private
function Window:open_window()
  if self.float.enable then
    vim.api.nvim_open_win(0, true, self:open_win_config())
  else
    vim.api.nvim_command("vsp")
    self:reposition_window()
  end
  view.setup_tabpage(vim.api.nvim_get_current_tabpage())
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

---@param tabpage integer
local function close(tabpage)
  if not view.is_visible({ tabpage = tabpage }) then
    return
  end
  view.save_tab_state(tabpage)
  switch_buf_if_last_buf()
  local tree_win = view.get_winnr(tabpage)
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

function Window:close_this_tab_only()
  close(vim.api.nvim_get_current_tabpage())
end

function Window:close_all_tabs()
  view.all_tabs_callback(function(t)
    close(t)
  end)
end

---@param tabpage integer|nil
function Window:close(tabpage)
  if self.explorer.opts.tab.sync.close then
    self:close_all_tabs()
  elseif tabpage then
    close(tabpage)
  else
    self:close_this_tab_only()
  end
end

---@param options table|nil
function Window:open(options)
  if view.is_visible() then
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
function Window:grow()
  local starts_at = self:is_root_folder_visible(require("nvim-tree.core").get_cwd()) and 1 or 0
  local lines = vim.api.nvim_buf_get_lines(view.get_bufnr(), starts_at, -1, false)
  -- number of columns of right-padding to indicate end of path
  local padding = self:get_size(self.padding)

  -- account for sign/number columns etc.
  local wininfo = vim.fn.getwininfo(view.get_winnr())
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
    local extmarks = vim.api.nvim_buf_get_extmarks(view.get_bufnr(), ns_id, { line_nr, 0 }, { line_nr, -1 }, { details = true })
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

function Window:grow_from_content()
  if self.adaptive_size then
    self:grow()
  end
end

---@param size string|number|nil
function Window:resize(size)
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

  if not view.is_visible() then
    return
  end

  local winnr = view.get_winnr() or 0

  local new_size = self:get_width()

  if new_size ~= vim.api.nvim_win_get_width(winnr) then
    vim.api.nvim_win_set_width(winnr, new_size)
    if not self.preserve_window_proportions then
      vim.cmd(":wincmd =")
    end
  end

  events._dispatch_on_tree_resize(new_size)
end

---@private
function Window:reposition_window()
  vim.api.nvim_command("wincmd " .. (self.side == "left" and "H" or "L"))
  self:resize()
end

---Open the tree in the a window
---@param opts OpenInWinOpts|nil
function Window:open_in_win(opts)
  opts = opts or { hijack_current_buf = true, resize = true }
  events._dispatch_on_tree_pre_open()
  if opts.winid and vim.api.nvim_win_is_valid(opts.winid) then
    vim.api.nvim_set_current_win(opts.winid)
  end
  self:create_buffer(opts.hijack_current_buf and vim.api.nvim_get_current_buf())
  view.setup_tabpage(vim.api.nvim_get_current_tabpage())
  view.set_current_win()
  self:set_window_options_and_buffer()
  if opts.resize then
    self:reposition_window()
    self:resize()
  end
  events._dispatch_on_tree_open()
end

---@param winnr number|nil
---@param open_if_closed boolean|nil
function Window:focus(winnr, open_if_closed)
  local wnr = winnr or view.get_winnr()

  if vim.api.nvim_win_get_tabpage(wnr or 0) ~= vim.api.nvim_win_get_tabpage(0) then
    self:close()
    self:open()
    wnr = view.get_winnr()
  elseif open_if_closed and not view.is_visible() then
    self:open()
  end

  if wnr then
    vim.api.nvim_set_current_win(wnr)
  end
end

function Window:prevent_buffer_override()
  local view_winnr = view.get_winnr()
  local view_bufnr = view.get_bufnr()

  -- need to schedule to let the new buffer populate the window
  -- because this event needs to be run on bufWipeout.
  -- Otherwise the curwin/curbuf would match the view buffer and the view window.
  vim.schedule(function()
    local curwin = vim.api.nvim_get_current_win()
    local curwinconfig = vim.api.nvim_win_get_config(curwin)
    local curbuf = vim.api.nvim_win_get_buf(curwin)
    local bufname = vim.api.nvim_buf_get_name(curbuf)

    if not bufname:match("NvimTree") then
      view.clear_tabpage(view_winnr)
    end
    if curwin ~= view_winnr or bufname == "" or curbuf == view_bufnr then
      return
    end

    -- patch to avoid the overriding window to be fixed in size
    -- might need a better patch
    vim.cmd("setlocal nowinfixwidth")
    vim.cmd("setlocal nowinfixheight")
    self:open({ focus_tree = false })

    self.explorer.renderer:draw()

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
function Window:is_root_folder_visible(cwd)
  return cwd ~= "/" and not self.hide_root_folder
end

-- used on ColorScheme event
function Window:reset_winhl()
  local winnr = view.get_winnr()
  if winnr and vim.api.nvim_win_is_valid(winnr) then
    vim.wo[view.get_winnr()].winhl = appearance.WIN_HL
  end
end

---Check if width determined or calculated on-fly
---@return boolean
function Window:is_width_determined()
  return type(self.width) ~= "function"
end

---Configure width-related config
---@param width string|function|number|table|nil
function Window:configure_width(width)
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

return Window
