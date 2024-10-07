local DirectoryNode = require("nvim-tree.node.directory")
local LinkNode = require("nvim-tree.node.link")
local FileNode = require("nvim-tree.node.file")
local Watcher = require("nvim-tree.watcher")

local M = {}

---Factory function to create the appropriate Node
---@param explorer Explorer
---@param parent Node
---@param abs string
---@param stat uv.fs_stat.result? -- on nil stat return nil Node
---@param name string
---@return Node?
function M.create_node(explorer, parent, abs, stat, name)
  if not stat then
    return nil
  end

  if stat.type == "directory" and vim.loop.fs_access(abs, "R") and Watcher.is_fs_event_capable(abs) then
    return DirectoryNode:create(explorer, parent, abs, name, stat)
  elseif stat.type == "file" then
    return FileNode:create(explorer, parent, abs, name, stat)
  elseif stat.type == "link" then
    return LinkNode:create(explorer, parent, abs, name, stat)
  end

  return nil
end

return M
