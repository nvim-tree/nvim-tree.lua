local log = require("nvim-tree.log")
local git = require("nvim-tree.git")
local utils = require("nvim-tree.utils")
local notify = require("nvim-tree.notify")
local Watcher = require("nvim-tree.watcher").Watcher

local M = {
  config = {},
  uid = 0,
}

---@param path string
---@return boolean
local function is_git(path)
  -- If $GIT_DIR is set, consider its value to be equivalent to '.git'.
  -- Expand $GIT_DIR (and `path`) to a full path (see :help filename-modifiers), since
  -- it's possible to set it to a relative path. We want to make our best
  -- effort to expand that to a valid absolute path.
  if vim.fn.fnamemodify(path, ":p") == vim.fn.fnamemodify(vim.env.GIT_DIR, ":p") then
    return true
  elseif vim.fn.fnamemodify(path, ":t") == ".git" then
    return true
  else
    return false
  end
end

local IGNORED_PATHS = {
  -- disable watchers on kernel filesystems
  -- which have a lot of unwanted events
  "/sys",
  "/proc",
  "/dev",
}

---@param path string
---@return boolean
local function is_folder_ignored(path)
  for _, folder in ipairs(IGNORED_PATHS) do
    if vim.startswith(path, folder) then
      return true
    end
  end

  if type(M.config.filesystem_watchers.ignore_dirs) == "table" then
    for _, ignore_dir in ipairs(M.config.filesystem_watchers.ignore_dirs) do
      if utils.is_windows then
        ignore_dir = ignore_dir:gsub("/", "\\\\") or ignore_dir
      end

      if vim.fn.match(path, ignore_dir) ~= -1 then
        return true
      end
    end
  elseif type(M.config.filesystem_watchers.ignore_dirs) == "function" then
    return M.config.filesystem_watchers.ignore_dirs(path)
  end

  return false
end

---@param node DirectoryNode
---@return Watcher|nil
function M.create_watcher(node)
  if not M.config.filesystem_watchers.enable or type(node) ~= "table" then
    return nil
  end

  local path = node.link_to or node.absolute_path
  if is_git(path) or is_folder_ignored(path) then
    return nil
  end

  ---@param watcher Watcher
  local function callback(watcher)
    log.line("watcher", "node event scheduled refresh %s", watcher.data.context)

    -- event is awaiting debouncing and handling
    watcher.data.outstanding_events = watcher.data.outstanding_events + 1

    -- disable watcher when outstanding exceeds max
    if M.config.filesystem_watchers.max_events > 0 and watcher.data.outstanding_events > M.config.filesystem_watchers.max_events then
      notify.error(string.format(
        "Observed %d consecutive file system events with interval < %dms, exceeding filesystem_watchers.max_events=%s. Disabling watcher for directory '%s'. Consider adding this directory to filesystem_watchers.ignore_dirs",
        watcher.data.outstanding_events,
        M.config.filesystem_watchers.debounce_delay,
        M.config.filesystem_watchers.max_events,
        node.absolute_path
      ))
      node:destroy_watcher()
    end

    utils.debounce(watcher.data.context, M.config.filesystem_watchers.debounce_delay, function()
      if watcher.destroyed then
        return
      end

      -- event has been handled
      watcher.data.outstanding_events = 0

      if node.link_to then
        log.line("watcher", "node event executing refresh '%s' -> '%s'", node.link_to, node.absolute_path)
      else
        log.line("watcher", "node event executing refresh '%s'", node.absolute_path)
      end
      git.refresh_dir(node)
    end)
  end

  M.uid = M.uid + 1
  return Watcher:create({
    path = path,
    callback = callback,
    data = {
      context = "explorer:watch:" .. path .. ":" .. M.uid,
      outstanding_events = 0, -- unprocessed events that have not been debounced
    }
  })
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
  M.uid = 0
end

return M
