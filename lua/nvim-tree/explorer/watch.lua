local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local Watcher = require("nvim-tree.watcher").Watcher

local M = {}

local function is_git(path)
  return vim.fn.fnamemodify(path, ":t") == ".git"
end

local IGNORED_PATHS = {
  -- disable watchers on kernel filesystems
  -- which have a lot of unwanted events
  "/sys",
  "/proc",
  "/dev",
}

local function is_folder_ignored(path)
  for _, folder in ipairs(IGNORED_PATHS) do
    if vim.startswith(path, folder) then
      return true
    end
  end

  for _, ignore_dir in ipairs(M.ignore_dirs) do
    if vim.fn.match(path, ignore_dir) ~= -1 then
      return true
    end
  end

  return false
end

function M.create_watcher(absolute_path)
  if not M.enabled then
    return nil
  end
  if is_git(absolute_path) or is_folder_ignored(absolute_path) then
    return nil
  end

  local function callback(watcher)
    log.line("watcher", "node event scheduled %s", watcher.context)
    utils.debounce(watcher.context, M.debounce_delay, function()
      log.line("watcher", "node event executing '%s'", watcher._path)
      require("nvim-tree.explorer.reload").refresh_path(watcher._path)
    end)
  end

  M.uid = M.uid + 1
  return Watcher:new(absolute_path, callback, {
    context = "explorer:watch:" .. absolute_path .. ":" .. M.uid,
  })
end

function M.setup(opts)
  M.enabled = opts.filesystem_watchers.enable
  M.debounce_delay = opts.filesystem_watchers.debounce_delay
  M.ignore_dirs = opts.filesystem_watchers.ignore_dirs
  M.uid = 0
end

return M
