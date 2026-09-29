local n = require("test.functional.testnvim")()
local t = require("test.testutil")

local M = {}

---Assert path exists and is a directory
---@param path string absolute
function M.dir_exists(path)
  local stat, err = vim.uv.fs_stat(path)
  t.eq(nil,         err,                path)
  t.eq("directory", stat and stat.type, path)
end

---Assert path exists and is a file
---@param path string absolute
function M.file_exists(path)
  local stat, err = vim.uv.fs_stat(path)
  t.eq(nil,    err,                path)
  t.eq("file", stat and stat.type, path)
end

---Assert events received during a functest, recorded in session global NVT_FUNCTEST_EVENTS
---Must be subscribed via event_subscribe
---@param events nvt.functest.event[]
function M.events_received(events)
  t.eq(events, n.exec_lua(function()
    return NVT_FUNCTEST_EVENTS
  end))
end

return M
