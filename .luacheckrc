local M = {}

-- Don't report unused self arguments of methods.
M.self = false

M.ignore = {
  "631",  -- max_line_length
}

-- Global objects defined by the C code
M.globals = {
  "vim",
}

return M
