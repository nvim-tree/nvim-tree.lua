local DirectoryNode = require("nvim-tree.node.directory")
local LinkNode = require("nvim-tree.node.link")
local FileNode = require("nvim-tree.node.file")
local Watcher = require("nvim-tree.watcher")

local M = {}

---@param explorer Explorer
-----@param parent DirectoryNode    -- TODO #2871 #2886
---@param abs string
---@param stat uv.fs_stat.result|nil
---@param name string
---@return Node|nil
function M.create_node(explorer, parent, abs, stat, name)
  if not stat then
    return nil
  end

  if stat.type == "directory" and vim.loop.fs_access(abs, "R") and Watcher.is_fs_event_capable(abs) then
    return DirectoryNode:new(explorer, parent, abs, name, stat)
  elseif stat.type == "file" then
    return FileNode:new(explorer, parent, abs, name, stat)
  elseif stat.type == "link" then
    local link = LinkNode:new(explorer, parent, abs, name, stat)
    if link.link_to ~= nil then
      return link
    end
  end

  return nil
end

return M
