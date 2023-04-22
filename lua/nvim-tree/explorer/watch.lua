local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local Watcher = require("nvim-tree.watcher").Watcher

local M = {}

M.ignore_dirs = {
  -- disable watchers on kernel filesystems
  -- which have a lot of unwanted events
  "/sys",
  "/proc",
  "/dev",
}

function M.ignore_dir(path)
  table.insert(M.ignore_dirs, path)
end

local function is_folder_ignored(path)
  for _, ignore_dir in ipairs(M.ignore_dirs) do
    if vim.fn.match(path, ignore_dir) ~= -1 then
      return true
    end
  end

  return false
end

function M.create_watcher(node)
  if not M.enabled or type(node) ~= "table" then
    return nil
  end

  local path
  if node.type == "link" then
    path = node.link_to
  else
    path = node.absolute_path
  end

  if is_folder_ignored(path) then
    return nil
  end

  local function callback(watcher)
    log.line("watcher", "node event scheduled refresh %s", watcher.context)
    utils.debounce(watcher.context, M.debounce_delay, function()
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
  M.enabled = opts.filesystem_watchers.enable
  M.debounce_delay = opts.filesystem_watchers.debounce_delay
  M.ignore_dirs = vim.tbl_extend("force", M.ignore_dirs, opts.filesystem_watchers.ignore_dirs)
  M.uid = 0
end

return M
