local uv = vim.loop

local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"

local M = {
  _watchers = {},
}
local Watcher = {}
Watcher.__index = Watcher

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

  self._p, _, name = uv.new_fs_poll()
  if not self._p then
    self._p = nil
    utils.warn(
      string.format("Could not initialize an fs_poll watcher for path %s : %s", self._opts.absolute_path, name)
    )
    return nil
  end

  local poll_cb = vim.schedule_wrap(function(err)
    if err then
      log.line("watcher", "poll_cb for %s fail : %s", self._opts.absolute_path, err)
    else
      self._opts.on_event(self._opts)
    end
  end)

  rc, _, name = uv.fs_poll_start(self._p, self._opts.absolute_path, self._opts.interval, poll_cb)
  if rc ~= 0 then
    utils.warn(string.format("Could not start the fs_poll watcher for path %s : %s", self._opts.absolute_path, name))
    return nil
  end

  return self
end

function Watcher:stop()
  log.line("watcher", "Watcher:stop  '%s'", self._opts.absolute_path)
  if self._p then
    local rc, _, name = uv.fs_poll_stop(self._p)
    if rc ~= 0 then
      utils.warn(string.format("Could not stop the fs_poll watcher for path %s : %s", self._opts.absolute_path, name))
    end
    self._p = nil
  end
end

M.Watcher = Watcher

function M.purge_watchers()
  for _, watcher in pairs(M._watchers) do
    watcher:stop()
  end
  M._watchers = {}
end

return M
