local M = {}

---Setup options for "highlight_*"
---@enum HL_POSITION
M.HL_POSITION = {
  none = 0,
  icon = 1,
  name = 2,
  all = 4,
}

---Setup options for "*_placement"
---@enum ICON_PLACEMENT
M.ICON_PLACEMENT = {
  none = 0,
  signcolumn = 1,
  before = 2,
  after = 3,
  right_align = 4,
}

---Reason for filter in filter.lua
---@enum FILTER_REASON
M.FILTER_REASON = {
  none = 0, -- It's not filtered
  git = 1,
  buf = 2,
  dotfile = 4,
  custom = 8,
  bookmark = 16,
}

return M
