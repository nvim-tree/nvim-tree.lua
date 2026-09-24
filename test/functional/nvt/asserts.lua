local t = require("test.testutil")

local M = {}

function M.dir_exists(path)
  local stat, err = vim.uv.fs_stat(path)
  t.eq(nil,         err,                path)
  t.eq("directory", stat and stat.type, path)
end

function M.file_exists(path)
  local stat, err = vim.uv.fs_stat(path)
  t.eq(nil,    err,                path)
  t.eq("file", stat and stat.type, path)
end

return M
