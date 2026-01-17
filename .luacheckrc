local M = {}

-- Don't report unused self arguments of methods.
M.self = false

M.ignore = {
  "631",  -- max_line_length
  "212", -- TODO #3088 make luacheck understand @meta
}

-- Global objects defined by the C code
M.globals = {
  "vim",
}

return M
