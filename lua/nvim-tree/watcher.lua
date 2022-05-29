local uv = vim.loop

local utils = require "nvim-tree.utils"

local M = {}
local Watcher = {}
Watcher.__index = Watcher

function Watcher.new(opts)
  if not M.enabled then
    return nil
  end

  local ok, fs_event = pcall(uv.new_fs_event)
  if not ok then
    utils.warn(string.format("Could not initialize a watcher for path %s", opts.absolute_path))
    return nil
  end

  local watcher = setmetatable({
    _path = opts.absolute_path,
    _w = fs_event,
  }, Watcher)

  return watcher:start(opts)
end

function Watcher:start(opts)
  local ok = pcall(
    uv.fs_event_start,
    self._w,
    self._path,
    {},
    vim.schedule_wrap(function()
      opts.on_event(self._path)
    end)
  )
  if not ok then
    utils.warn(string.format("Could not start the watcher for path %s", self._path))
    return nil
  end

  return self
end

function Watcher:stop()
  if self._w then
    uv.fs_event_stop(self._w)
  end
end

function Watcher:restart()
  self:stop()
  return self:start()
end

function M.setup(opts)
  M.enabled = opts.experimental_watchers
end

M.Watcher = Watcher

return M
