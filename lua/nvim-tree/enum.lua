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
}

return M
