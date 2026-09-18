local M = {}

-- Don't report unused self arguments of methods.
M.self = false

M.ignore = {
  "631", -- max_line_length
}

M.globals = {
  -- Global objects defined by the C code
  "vim",
  -- Global neovim test functions
  "it",
  "describe",
  "pending",
  "setup",
  "before_each",
  "after_each",
  "teardown",
  "finally",
}

return M
