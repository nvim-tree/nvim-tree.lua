---Idea taken from: https://github.com/ms-jpq/lua-async-await
local co = coroutine

local M = {}

---@type table<thread, boolean>
local async_threads = {}

---Execuate an asynchronous function
---@param func function
---@param ... any The arguments passed to `func`, plus a callback receives (err, ...result)
function M.exec(func, ...)
  local nargs = select("#", ...)
  local args = { ... }
  ---@type function
  local cb = function() end
  if nargs > 0 then
    cb = args[nargs]
    args[nargs] = nil
  end

  local thread = co.create(func)
  async_threads[thread] = true

  local function step(...)
    local res = { co.resume(thread, ...) }
    local ok = table.remove(res, 1)
    local err_or_next = res[1]
    if co.status(thread) ~= "dead" then
      local _, err = xpcall(err_or_next, debug.traceback, step)
      if err then
        cb(err)
      end
    else
      async_threads[thread] = nil
      if ok then
        cb(nil, unpack(res))
      else
        cb(debug.traceback(thread, err_or_next))
      end
    end
  end

  step(unpack(args))
end

---Test whether we are in async context
---@return boolean
function M.in_async()
  local thread = co.running()
  return async_threads[thread] ~= nil
end

---Asynchronously call a function, which has callback as the last parameter (like luv apis)
---@param func function
---@param ... any
---@return any
function M.call(func, ...)
  local args = { ... }
  return co.yield(function(cb)
    table.insert(args, cb)
    func(unpack(args))
  end)
end

---Asynchronous `vim.schedule`
---See `:h lua-loop-callbacks` and `:h api-fast`. Usually this should be used before `vim.api.*` and `vim.fn.*` calls.
function M.schedule()
  return co.yield(function(cb)
    vim.schedule(cb)
  end)
end

return M
