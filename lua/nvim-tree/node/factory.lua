local DirectoryNode = require("nvim-tree.node.directory")
local LinkNode = require("nvim-tree.node.link")
local FileNode = require("nvim-tree.node.file")
local Watcher = require("nvim-tree.watcher")

local M = {}

--- TODO merge #2922 and pass just stat, as stat.type from lstat is correct

---Factory function to create the appropriate Node
---@param explorer Explorer
---@param parent Node
---@param abs string
---@param t string? type from vim.loop.fs_scandir_next as stat.type is incorrectly reported as a file for links
---@param stat uv.fs_stat.result?
---@param name string
---@return Node?
function M.create_node(explorer, parent, abs, t, stat, name)
  if not stat then
    return nil
  end

  if t == "directory" and vim.loop.fs_access(abs, "R") and Watcher.is_fs_event_capable(abs) then
    return DirectoryNode:create(explorer, parent, abs, name, stat)
  elseif t == "file" then
    return FileNode:create(explorer, parent, abs, name, stat)
  elseif t == "link" then
    return LinkNode:create(explorer, parent, abs, name, stat)
  end

  return nil
end

return M
