-- global state, to be refactored away during multi-instance

local M = {
  -- from View
  TABPAGES = {},
  BUFNR_PER_TAB = {},
  CURSORS = {},
}

return M
