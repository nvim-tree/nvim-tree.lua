local utils = require("nvim-tree.utils")

local M = {}

local BUFNR_PER_TAB = {}
local CURSORS = {}
local TABPAGES = {}

-- The initial state of a tab
local tabinitial = {
  -- The position of the cursor { line, column }
  cursor = { 0, 0 },
  -- The NvimTree window number
  winnr = nil,
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

function M.wipe_rogue_buffer()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not matches_bufnr(bufnr) and utils.is_nvim_tree_buf(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

---@param bufnr integer|boolean|nil
---@return integer tab
function M.create_buffer(bufnr)
  local tab = vim.api.nvim_get_current_tabpage()
  BUFNR_PER_TAB[tab] = bufnr or vim.api.nvim_create_buf(false, false)
  return tab
end

-- setup_tabpage sets up the initial state of a tab
---@param tabpage integer
function M.setup_tabpage(tabpage)
  local winnr = vim.api.nvim_get_current_win()
  TABPAGES[tabpage] = vim.tbl_extend("force", TABPAGES[tabpage] or tabinitial, { winnr = winnr })
end

-- save_tab_state saves any state that should be preserved across redraws.
---@param tabnr integer
function M.save_tab_state(tabnr)
  local tabpage = tabnr or vim.api.nvim_get_current_tabpage()
  CURSORS[tabpage] = vim.api.nvim_win_get_cursor(M.get_winnr(tabpage) or 0)
end

---@param fn fun(tabpage: integer)
function M.all_tabs_callback(fn)
  for tabpage, _ in pairs(TABPAGES) do
    fn(tabpage)
  end
end

function M.set_current_win()
  local current_tab = vim.api.nvim_get_current_tabpage()
  TABPAGES[current_tab].winnr = vim.api.nvim_get_current_win()
end

function M.abandon_current_window()
  local tab = vim.api.nvim_get_current_tabpage()
  BUFNR_PER_TAB[tab] = nil
  if TABPAGES[tab] then
    TABPAGES[tab].winnr = nil
  end
end

function M.abandon_all_windows()
  for tab, _ in pairs(vim.api.nvim_list_tabpages()) do
    BUFNR_PER_TAB[tab] = nil
    if TABPAGES[tab] then
      TABPAGES[tab].winnr = nil
    end
  end
end

---@param opts table|nil
---@return boolean
function M.is_visible(opts)
  if opts and opts.tabpage then
    if TABPAGES[opts.tabpage] == nil then
      return false
    end
    local winnr = TABPAGES[opts.tabpage].winnr
    return winnr and vim.api.nvim_win_is_valid(winnr)
  end

  if opts and opts.any_tabpage then
    for _, v in pairs(TABPAGES) do
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

--- Retrieve the winid of the open tree.
---@param opts ApiTreeWinIdOpts|nil
---@return number|nil winid unlike get_winnr(), this returns nil if the nvim-tree window is not visible
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
  M.set_cursor(CURSORS[tabpage])
end

--- Returns the window number for nvim-tree within the tabpage specified
---@param tabpage number|nil (optional) the number of the chosen tabpage. Defaults to current tabpage.
---@return number|nil
function M.get_winnr(tabpage)
  tabpage = tabpage or vim.api.nvim_get_current_tabpage()
  local tabinfo = TABPAGES[tabpage]
  if tabinfo and tabinfo.winnr and vim.api.nvim_win_is_valid(tabinfo.winnr) then
    return tabinfo.winnr
  end
end

--- Returns the current nvim tree bufnr
---@return number
function M.get_bufnr()
  return BUFNR_PER_TAB[vim.api.nvim_get_current_tabpage()]
end

---@param winnr number|nil
function M.clear_tabpage(winnr)
  for i, tabpage in ipairs(TABPAGES) do
    if tabpage.winnr == winnr then
      TABPAGES[i] = nil
      break
    end
  end
end

return M
