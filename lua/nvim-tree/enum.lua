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
  signcolumn = 0,
  before = 1,
  after = 2,
}

return M
