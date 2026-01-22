 local M = {}

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
