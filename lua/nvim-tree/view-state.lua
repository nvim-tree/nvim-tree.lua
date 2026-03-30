local config = require("nvim-tree.config")

local M = {}

local DEFAULT_MIN_WIDTH = 30
local DEFAULT_MAX_WIDTH = -1
local DEFAULT_LINES_EXCLUDED = {
  "root",
}
local DEFAULT_PADDING = 1

M.Active = {
  adaptive_size = false,
  tabpages      = {},
  cursors       = {},
  winopts       = {
    relativenumber = false,
    number         = false,
    list           = false,
    foldenable     = false,
    winfixwidth    = true,
    winfixheight   = true,
    spell          = false,
    signcolumn     = "yes",
    foldmethod     = "manual",
    foldcolumn     = "0",
    cursorcolumn   = false,
    cursorline     = true,
    cursorlineopt  = "both",
    colorcolumn    = "0",
    wrap           = false,
    winhl          = table.concat({
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
      "FloatBorder:NvimTreeNormalFloatBorder",
    }, ","),
  },
}

---@param size (fun():integer)|integer|string
---@return integer
function M.get_size(size)
  if type(size) == "number" then
    return size
  elseif type(size) == "function" then
    return M.get_size(size())
  end
  local size_as_number = tonumber(size:sub(0, -2))
  local percent_as_decimal = size_as_number / 100
  return math.floor(vim.o.columns * percent_as_decimal)
end

---@param size (fun():integer)|integer|nil
---@return integer
function M.get_width(size)
  if size then
    return M.get_size(size)
  else
    return M.get_size(M.Active.width)
  end
end

---Configure width-related config
---@param width string|function|number|table|nil
local function configure_width(width)
  if type(width) == "table" then
    M.Active.adaptive_size = true
    M.Active.width = width.min or DEFAULT_MIN_WIDTH
    M.Active.max_width = width.max or DEFAULT_MAX_WIDTH
    local lines_excluded = width.lines_excluded or DEFAULT_LINES_EXCLUDED
    M.Active.root_excluded = vim.tbl_contains(lines_excluded, "root")
    M.Active.padding = width.padding or DEFAULT_PADDING
  elseif width == nil then
    if config.g.view.width ~= nil then
      -- if we had input config - fallback to it
      M.configure_width(config.g.view.width)
    else
      -- otherwise - restore initial width
      M.Active.width = M.Active.initial_width
    end
  else
    M.Active.adaptive_size = false
    M.Active.width = width
  end
end

---Apply global configuration to Active
function M.initialize()
  M.Active.winopts.cursorline = config.g.view.cursorline
  M.Active.winopts.cursorlineopt = config.g.view.cursorlineopt
  M.Active.winopts.number = config.g.view.number
  M.Active.winopts.relativenumber = config.g.view.relativenumber
  M.Active.winopts.signcolumn = config.g.view.signcolumn

  configure_width(config.g.view.width)

  M.Active.initial_width = M.get_width()
end

return M
