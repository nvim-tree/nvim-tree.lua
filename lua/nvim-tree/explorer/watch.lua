local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
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

  for _, ignore_dir in ipairs(M.config.filesystem_watchers.ignore_dirs) do
    if vim.fn.match(path, ignore_dir) ~= -1 then
      return true
    end
  end

  return false
end

---@param node Node
---@return Watcher|nil
function M.create_watcher(node)
  if not M.config.filesystem_watchers.enable or type(node) ~= "table" then
    return nil
  end

  local path = node.link_to or node.absolute_path
  if is_git(path) or is_folder_ignored(path) then
    return nil
  end

  local function callback(watcher)
    log.line("watcher", "node event scheduled refresh %s", watcher.context)
    utils.debounce(watcher.context, M.config.filesystem_watchers.debounce_delay, function()
      if watcher.destroyed then
        return
      end
      if node.link_to then
        log.line("watcher", "node event executing refresh '%s' -> '%s'", node.link_to, node.absolute_path)
      else
        log.line("watcher", "node event executing refresh '%s'", node.absolute_path)
      end
      require("nvim-tree.explorer.reload").refresh_node(node, function()
        require("nvim-tree.renderer").draw()
      end)
    end)
  end

  M.uid = M.uid + 1
  return Watcher:new(path, nil, callback, {
    context = "explorer:watch:" .. path .. ":" .. M.uid,
  })
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
  M.uid = 0
end

return M
