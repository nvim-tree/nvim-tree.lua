local uv = vim.loop

local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"

local M = {
  _watchers = {},
}
local Watcher = {}
Watcher.__index = Watcher

local FS_EVENT_FLAGS = {
  -- inotify or equivalent will be used; fallback to stat has not yet been implemented
  stat = false,
  -- recursive is not functional in neovim's libuv implementation
  recursive = false,
}

function Watcher.new(opts)
  for _, existing in ipairs(M._watchers) do
    if existing._opts.absolute_path == opts.absolute_path then
      log.line("watcher", "Watcher:new using existing '%s'", opts.absolute_path)
      return existing
    end
  end

  log.line("watcher", "Watcher:new '%s'", opts.absolute_path)

  local watcher = setmetatable({
    _opts = opts,
  }, Watcher)

  watcher = watcher:start()

  table.insert(M._watchers, watcher)

  return watcher
end

function Watcher:start()
  log.line("watcher", "Watcher:start '%s'", self._opts.absolute_path)

  local rc, _, name

  self._e, _, name = uv.new_fs_event()
  if not self._e then
    self._e = nil
    utils.warn(
      string.format("Could not initialize an fs_event watcher for path %s : %s", self._opts.absolute_path, name)
    )
    return nil
  end

  local event_cb = vim.schedule_wrap(function(err, filename, events)
    if err then
      log.line("watcher", "event_cb for %s fail : %s", self._opts.absolute_path, err)
    else
      log.line("watcher", "event_cb '%s' '%s' %s", self._opts.absolute_path, filename, vim.inspect(events))
      self._opts.on_event(self._opts)
    end
  end)

  rc, _, name = self._e:start(self._opts.absolute_path, FS_EVENT_FLAGS, event_cb)
  if rc ~= 0 then
    utils.warn(string.format("Could not start the fs_event watcher for path %s : %s", self._opts.absolute_path, name))
    return nil
  end

  return self
end

function Watcher:destroy()
  log.line("watcher", "Watcher:destroy '%s'", self._opts.absolute_path)
  if self._e then
    local rc, _, name = self._e:stop()
    if rc ~= 0 then
      utils.warn(string.format("Could not stop the fs_event watcher for path %s : %s", self._opts.absolute_path, name))
    end
    self._e = nil
  end
  for i, w in ipairs(M._watchers) do
    if w == self then
      table.remove(M._watchers, i)
      break
    end
  end
end

M.Watcher = Watcher

function M.purge_watchers()
  for _, watcher in pairs(M._watchers) do
    watcher:destroy()
  end
  M._watchers = {}
end

return M
