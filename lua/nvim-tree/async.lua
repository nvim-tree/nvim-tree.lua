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

---Wrap an asynchronous function to be directly called in synchronous context
---@param func function
---@param argc number The number of arguments the wrapped function accepts. Pass it if you want the returned function to receive an additional callback as final argument, and the signature of callback is the same as that of `async.exec`.
---@return function
function M.wrap(func, argc)
  return function(...)
    local args = { ... }
    if argc == nil or #args == argc then
      table.insert(args, function() end)
    end
    M.exec(func, unpack(args))
  end
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

---Execuate multiple asynchronous function simultaneously
---@param ... fun()
---@return table[] (err, ...result) tuples from every function
function M.all(...)
  local tasks = { ... }
  if #tasks == 0 then
    return {}
  end

  local results = {}
  local finished = 0
  return co.yield(function(cb)
    for i, task in ipairs(tasks) do
      M.exec(task, function(...)
        finished = finished + 1
        results[i] = { ... }
        if finished == #tasks then
          cb(results)
        end
      end)
    end
  end)
end

---Asynchronous `vim.schedule`
function M.schedule()
  return co.yield(function(cb)
    vim.schedule(cb)
  end)
end

---@class Interrupter
---@field yield fun()
---@field interval number
---@field last number
local Interrupter = {}

---@return Interrupter
function Interrupter.new(ms, yield)
  local obj = {
    interval = ms or 12,
    last = vim.loop.hrtime(),
    yield = yield or M.schedule,
  }
  setmetatable(obj, { __index = Interrupter })
  return obj
end

function Interrupter:check()
  local cur = vim.loop.hrtime()
  if cur - self.last >= self.interval * 1000000 then
    self:yield()
    self.last = cur
  end
end

M.Interrupter = Interrupter

---This is useful for cancelling execution async function
---@class AbortSignal
---@field aborted boolean
---@field reason any
---@field private abort_cbs function[]
local AbortSignal = {}

---@return AbortSignal
function AbortSignal.new()
  local obj = {
    aborted = false,
    reason = nil,
    abort_cbs = {},
  }

  setmetatable(obj, { __index = AbortSignal })
  return obj
end

function AbortSignal:abort(reason)
  if not self.aborted then
    self.aborted = true
    self.reason = reason
    for _, cb in pairs(self.abort_cbs) do
      cb(reason)
    end
  end
end

---@param cb function
function AbortSignal:on_abort(cb)
  table.insert(self.abort_cbs, cb)
end

function AbortSignal:throw_if_aborted()
  if self.aborted then
    error(self.reason)
  end
end

M.AbortSignal = AbortSignal

return M
