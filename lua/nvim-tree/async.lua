---Idea taken from: https://github.com/ms-jpq/lua-async-await
local co = coroutine

local M = {}

---Execuate an asynchronous function
---@param func function
---@param ... any The arguments passed to `func`, plus a callback receives (err, ...result)
function M.exec(func, ...)
  local args = { ... }
  local cb = table.remove(args) or function() end
  local thread = co.create(func)

  local function step(...)
    local res = { co.resume(thread, ...) }
    local ok = table.remove(res, 1)
    local err_or_next = res[1]
    if co.status(thread) ~= "dead" then
      local _, err = xpcall(err_or_next, debug.traceback, step)
      if err then
        cb(err)
      end
    elseif ok then
      cb(nil, unpack(res))
    else
      cb(debug.traceback(thread, err_or_next))
    end
  end

  step(...)
end

---Wrap an asynchronous function to be directly called in synchronous context
---@param func function
---@param args_count number The number of arguments the wrapped function accepts. Pass it if you want the returned function to receive an additional callback as final argument, and the signature of callback is the same as that of `async.exec`.
---@return function
function M.wrap(func, args_count)
  return function(...)
    local args = { ... }
    if args_count == nil or #args == args_count then
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

function M.unwrap_err(...)
  local args = { ... }
  local err = table.remove(args, 1)
  if err then
    error(err)
  end
  return unpack(args)
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

return M
