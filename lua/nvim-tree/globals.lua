-- global state, to be refactored away during multi-instance

local M = {
  -- from View
  WINID_PER_TAB = {},
  BUFNR_PER_TAB = {},
  CURSORS = {},
}

return M
