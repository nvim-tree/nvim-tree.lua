local uv = vim.loop

local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"

local M = {}

local Event = {
  _events = {},
}
Event.__index = Event

local Watcher = {
  _watchers = {},
}
Watcher.__index = Watcher

local FS_EVENT_FLAGS = {
  -- inotify or equivalent will be used; fallback to stat has not yet been implemented
  stat = false,
  -- recursive is not functional in neovim's libuv implementation
  recursive = false,
}

function Event:new(path)
  log.line("watcher", "Event:new '%s'", path)

  local e = setmetatable({
    _path = path,
    _fs_event = nil,
    _listeners = {},
  }, Event)

  if e:start() then
    Event._events[path] = e
    return e
  else
    return nil
  end
end

function Event:start()
  log.line("watcher", "Event:start '%s'", self._path)

  local rc, _, name

  self._fs_event, _, name = uv.new_fs_event()
  if not self._fs_event then
    self._fs_event = nil
    utils.notify.warn(string.format("Could not initialize an fs_event watcher for path %s : %s", self._path, name))
    return false
  end

  local event_cb = vim.schedule_wrap(function(err, filename)
    if err then
      log.line("watcher", "event_cb for %s fail : %s", self._path, err)
    else
      log.line("watcher", "event_cb '%s' '%s'", self._path, filename)
      for _, listener in ipairs(self._listeners) do
        listener()
      end
    end
  end)

  rc, _, name = self._fs_event:start(self._path, FS_EVENT_FLAGS, event_cb)
  if rc ~= 0 then
    utils.notify.warn(string.format("Could not start the fs_event watcher for path %s : %s", self._path, name))
    return false
  end

  return true
end

function Event:add(listener)
  table.insert(self._listeners, listener)
end

function Event:remove(listener)
  utils.array_remove(self._listeners, listener)
  if #self._listeners == 0 then
    self:destroy()
  end
end

function Event:destroy()
  log.line("watcher", "Event:destroy '%s'", self._path)

  if self._fs_event then
    local rc, _, name = self._fs_event:stop()
    if rc ~= 0 then
      utils.notify.warn(string.format("Could not stop the fs_event watcher for path %s : %s", self._path, name))
    end
    self._fs_event = nil
  end

  Event._events[self._path] = nil
end

function Watcher:new(path, callback, data)
  log.line("watcher", "Watcher:new '%s'", path)

  local w = setmetatable(data, Watcher)

  w._event = Event._events[path] or Event:new(path)
  w._listener = nil
  w._path = path
  w._callback = callback

  if not w._event then
    return nil
  end

  w:start()

  table.insert(Watcher._watchers, w)

  return w
end

function Watcher:start()
  self._listener = function()
    self._callback(self)
  end

  self._event:add(self._listener)
end

function Watcher:destroy()
  log.line("watcher", "Watcher:destroy '%s'", self._path)

  self._event:remove(self._listener)

  utils.array_remove(Watcher._watchers, self)
end

M.Watcher = Watcher

function M.purge_watchers()
  log.line("watcher", "purge_watchers")

  for _, w in ipairs(utils.array_shallow_clone(Watcher._watchers)) do
    w:destroy()
  end

  for _, e in pairs(Event._events) do
    e:destroy()
  end
end

return M
