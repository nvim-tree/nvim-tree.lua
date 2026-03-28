local log = require("nvim-tree.log")
local git = require("nvim-tree.git")
local utils = require("nvim-tree.utils")
local notify = require("nvim-tree.notify")
local config = require("nvim-tree.config")
local Watcher = require("nvim-tree.watcher").Watcher

local M = {}

-- monotonically increasing, unique
local uid = 0

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

---Return true when a path is:
---- Blacklisted via {ignore_dirs}
---- Not whitelisted via {whitelist_dirs}, when it is not an empty table.
---@param path string
---@return boolean
local function is_folder_ignored(path)
  for _, folder in ipairs(IGNORED_PATHS) do
    if vim.startswith(path, folder) then
      return true
    end
  end

  ---Return true when p matches an entry in dirs, escaping for windows
  ---@param p string absolute path
  ---@param dirs string[] regexes
  ---@return boolean
  local function matches_dirs(p, dirs)
    for _, dir in ipairs(dirs) do
      if config.os.windows then
        dir = dir:gsub("/", "\\\\") or dir
      end

      if vim.fn.match(p, dir) ~= -1 then
        return true
      end
    end
    return false
  end

  if type(config.g.filesystem_watchers.ignore_dirs) == "table" then
    if matches_dirs(path, config.g.filesystem_watchers.ignore_dirs --[[@as string[] ]]) then
      return true
    end
  elseif type(config.g.filesystem_watchers.ignore_dirs) == "function" then
    if config.g.filesystem_watchers.ignore_dirs(path) then
      return true
    end
  end

  if type(config.g.filesystem_watchers.whitelist_dirs) == "table" and #config.g.filesystem_watchers.whitelist_dirs > 0 then
    if not matches_dirs(path, config.g.filesystem_watchers.whitelist_dirs --[[@as string[] ]]) then
      return true
    end
  elseif type(config.g.filesystem_watchers.whitelist_dirs) == "function" then
    if not config.g.filesystem_watchers.whitelist_dirs(path) then
      return true
    end
  end

  return false
end

---@param node DirectoryNode
---@return Watcher|nil
function M.create_watcher(node)
  if not config.g.filesystem_watchers.enable or type(node) ~= "table" then
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
    if config.g.filesystem_watchers.max_events > 0 and watcher.data.outstanding_events > config.g.filesystem_watchers.max_events then
      notify.error(string.format(
        "Observed %d consecutive file system events with interval < %dms, exceeding filesystem_watchers.max_events=%s. Disabling watcher for directory '%s'. Consider adding this directory to filesystem_watchers.ignore_dirs",
        watcher.data.outstanding_events,
        config.g.filesystem_watchers.debounce_delay,
        config.g.filesystem_watchers.max_events,
        node.absolute_path
      ))
      node:destroy_watcher()
    end

    utils.debounce(watcher.data.context, config.g.filesystem_watchers.debounce_delay, function()
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

  uid = uid + 1
  return Watcher:create({
    path = path,
    callback = callback,
    data = {
      context = "explorer:watch:" .. path .. ":" .. uid,
      outstanding_events = 0, -- unprocessed events that have not been debounced
    }
  })
end

return M
