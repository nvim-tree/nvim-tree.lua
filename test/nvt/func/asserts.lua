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

---Assert path does not exist
---@param path string absolute
function M.not_path_exists(path)
  local stat = vim.uv.fs_stat(path)
  t.eq(nil, stat, path)
end

---Assert events received during a functest, recorded in session global NVT_FUNCTEST_EVENTS
---Must be subscribed via event_subscribe
---Clears events as per ext_messages
---@param events test.nvt.func.fixtures.Event[]
function M.events_received(events)
  t.eq(events, n.exec_lua(function()
    local ev = vim.deepcopy(NVT_FUNCTEST_EVENTS)
    NVT_FUNCTEST_EVENTS = {}
    return ev
  end), "events_received")
end

---Assert events received during a functest, recorded in session global NVT_FUNCTEST_EVENTS
---Must be subscribed via event_subscribe
---Clears events as per ext_messages
---@param events test.nvt.func.fixtures.Event[]
function M.events_received_unordered(events)
  -- expected values removed when found
  local expected = vim.deepcopy(events)

  local actual = n.exec_lua(function()
    local ev = vim.deepcopy(NVT_FUNCTEST_EVENTS)
    NVT_FUNCTEST_EVENTS = {}
    return ev
  end)

  for _, a in pairs(actual) do
    local found = 0

    for i, e in ipairs(expected) do
      if vim.deep_equal(a, e) then
        found = i
        break
      end
    end

    if found == 0 then
      t.eq(events, actual, "events_received_unordered")
    end

    table.remove(expected, found)
  end

  if #expected > 0 then
    t.eq(events, actual, "events_received_unordered")
  end
end

---buffer with name exists and is loaded
---@param name string buffer name
---@return boolean
local function buf_loaded(name)
  return vim.tbl_contains(n.api.nvim_list_bufs(),
    function(buf)
      return n.api.nvim_buf_get_name(buf) == name and n.api.nvim_buf_is_loaded(buf)
    end, { predicate = true }
  )
end

---Assert buffer with name exists and is loaded
---@param name string buffer name
function M.buf_exists(name)
  t.eq(true, buf_loaded(name), "buffer '" .. name .. "' should be present and loaded")
end

---Assert buffer with name does not exist
---@param name string buffer name
function M.not_buf_exists(name)
  t.eq(false, buf_loaded(name), "buffer '" .. name .. "' should not be present")
end

return M
