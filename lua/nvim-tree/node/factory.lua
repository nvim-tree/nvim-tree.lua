local DirectoryLinkNode = require("nvim-tree.node.directory-link")
local DirectoryNode = require("nvim-tree.node.directory")
local FileLinkNode = require("nvim-tree.node.file-link")
local FileNode = require("nvim-tree.node.file")
local Watcher = require("nvim-tree.watcher")

local M = {}

---Factory function to create the appropriate Node
---@param explorer Explorer
---@param parent DirectoryNode
---@param absolute_path string
---@param stat uv.fs_stat.result? -- on nil stat return nil Node
---@param name string
---@return Node?
function M.create_node(explorer, parent, absolute_path, stat, name)
  if not stat then
    return nil
  end

  if stat.type == "directory" then
    -- directory must be readable and enumerable
    if vim.loop.fs_access(absolute_path, "R") and Watcher.is_fs_event_capable(absolute_path) then
      return DirectoryNode(explorer, parent, absolute_path, name, stat)
    end
  elseif stat.type == "file" then
    -- any file
    return FileNode(explorer, parent, absolute_path, name, stat)
  elseif stat.type == "link" then
    -- link target path and stat must resolve
    local link_to = vim.loop.fs_realpath(absolute_path)
    local link_to_stat = link_to and vim.loop.fs_stat(link_to)
    if not link_to or not link_to_stat then
      return
    end

    -- choose directory or file
    if link_to_stat.type == "directory" then
      return DirectoryLinkNode(explorer, parent, absolute_path, link_to, name, stat, link_to_stat)
    else
      return FileLinkNode(explorer, parent, absolute_path, link_to, name, stat, link_to_stat)
    end
  end

  return nil
end

return M
