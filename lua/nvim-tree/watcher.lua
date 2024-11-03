local notify = require("nvim-tree.notify")
local log = require("nvim-tree.log")
local utils = require("nvim-tree.utils")

local Class = require("nvim-tree.class")

local FS_EVENT_FLAGS = {
  -- inotify or equivalent will be used; fallback to stat has not yet been implemented
  stat = false,
  -- recursive is not functional in neovim's libuv implementation
  recursive = false,
}

local M = {
  config = {},
}

---@class (exact) Event: Class
---@field destroyed boolean
---@field private path string
---@field private fs_event uv.uv_fs_event_t?
---@field private listeners function[]
local Event = Class:new()

---Registry of all events
---@type Event[]
local events = {}

---Static factory method
---Creates and starts an Event
---@param path string
---@return Event|nil
function Event:create(path)
  log.line("watcher", "Event:create '%s'", path)

  ---@type Event
  local o = {
    destroyed = false,
    path = path,
    fs_event = nil,
    listeners = {},
  }
  o = self:new(o)

  if o:start() then
    events[path] = o
    return o
  else
    return nil
  end
end

---@return boolean
function Event:start()
  log.line("watcher", "Event:start '%s'", self.path)

  local rc, _, name

  self.fs_event, _, name = vim.loop.new_fs_event()
  if not self.fs_event then
    self.fs_event = nil
    notify.warn(string.format("Could not initialize an fs_event watcher for path %s : %s", self.path, name))
    return false
  end

  local event_cb = vim.schedule_wrap(function(err, filename)
    if err then
      log.line("watcher", "event_cb '%s' '%s' FAIL : %s", self.path, filename, err)
      local message = string.format("File system watcher failed (%s) for path %s, halting watcher.", err, self.path)
      if err == "EPERM" and (utils.is_windows or utils.is_wsl) then
        -- on directory removal windows will cascade the filesystem events out of order
        log.line("watcher", message)
        self:destroy()
      else
        self:destroy(message)
      end
    else
      log.line("watcher", "event_cb '%s' '%s'", self.path, filename)
      for _, listener in ipairs(self.listeners) do
        listener(filename)
      end
    end
  end)

  rc, _, name = self.fs_event:start(self.path, FS_EVENT_FLAGS, event_cb)
  if rc ~= 0 then
    if name == "EMFILE" then
      M.disable_watchers("fs.inotify.max_user_watches exceeded, see https://github.com/nvim-tree/nvim-tree.lua/wiki/Troubleshooting")
    else
      notify.warn(string.format("Could not start the fs_event watcher for path %s : %s", self.path, name))
    end
    return false
  end

  return true
end

---@param listener function
function Event:add(listener)
  table.insert(self.listeners, listener)
end

---@param listener function
function Event:remove(listener)
  utils.array_remove(self.listeners, listener)
  if #self.listeners == 0 then
    self:destroy()
  end
end

---@param message string|nil
function Event:destroy(message)
  log.line("watcher", "Event:destroy '%s'", self.path)

  if self.fs_event then
    if message then
      notify.warn(message)
    end

    local rc, _, name = self.fs_event:stop()
    if rc ~= 0 then
      notify.warn(string.format("Could not stop the fs_event watcher for path %s : %s", self.path, name))
    end
    self.fs_event = nil
  end

  self.destroyed = true
  events[self.path] = nil
end

---Static factory method
---Creates and starts a Watcher
---@class (exact) Watcher: Class
---@field data table user data
---@field destroyed boolean
---@field private path string
---@field private callback fun(watcher: Watcher)
---@field private files string[]?
---@field private listener fun(filename: string)?
---@field private event Event
local Watcher = Class:new()

---Registry of all watchers
---@type Watcher[]
local watchers = {}

---Static factory method
---@param path string
---@param files string[]|nil
---@param callback fun(watcher: Watcher)
---@param data table user data
---@return Watcher|nil
function Watcher:create(path, files, callback, data)
  log.line("watcher", "Watcher:create '%s' %s", path, vim.inspect(files))

  local event = events[path] or Event:create(path)
  if not event then
    return nil
  end

  ---@type Watcher
  local o = {
    data = data,
    destroyed = false,
    path = path,
    callback = callback,
    files = files,
    listener = nil,
    event = event,
  }
  o = self:new(o)

  o:start()

  table.insert(watchers, o)

  return o
end

function Watcher:start()
  self.listener = function(filename)
    if not self.files or vim.tbl_contains(self.files, filename) then
      self.callback(self)
    end
  end

  self.event:add(self.listener)
end

function Watcher:destroy()
  log.line("watcher", "Watcher:destroy '%s'", self.path)

  self.event:remove(self.listener)

  utils.array_remove(
    watchers,
    self
  )

  self.destroyed = true
end

M.Watcher = Watcher

--- Permanently disable watchers and purge all state following a catastrophic error.
---@param msg string
function M.disable_watchers(msg)
  notify.warn(string.format("Disabling watchers: %s", msg))
  M.config.filesystem_watchers.enable = false
  require("nvim-tree").purge_all_state()
end

function M.purge_watchers()
  log.line("watcher", "purge_watchers")

  for _, w in ipairs(utils.array_shallow_clone(watchers)) do
    w:destroy()
  end

  for _, e in pairs(events) do
    e:destroy()
  end
end

--- Windows NT will present directories that cannot be enumerated.
--- Detect these by attempting to start an event monitor.
---@param path string
---@return boolean
function M.is_fs_event_capable(path)
  if not utils.is_windows then
    return true
  end

  local fs_event = vim.loop.new_fs_event()
  if not fs_event then
    return false
  end

  if fs_event:start(path, FS_EVENT_FLAGS, function() end) ~= 0 then
    return false
  end

  if fs_event:stop() ~= 0 then
    return false
  end

  return true
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
end

return M
