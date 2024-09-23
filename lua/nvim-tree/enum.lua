local M = {}

---Must be synced with uv.fs_stat.result as it is compared with it
---@enum (key) NODE_TYPE
M.NODE_TYPE = {
  directory = 1,
  file = 2,
  link = 4,
}

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
