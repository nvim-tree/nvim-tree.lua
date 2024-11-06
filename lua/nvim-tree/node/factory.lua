local DirectoryLinkNode = require("nvim-tree.node.directory-link")
local DirectoryNode = require("nvim-tree.node.directory")
local FileLinkNode = require("nvim-tree.node.file-link")
local FileNode = require("nvim-tree.node.file")
local Watcher = require("nvim-tree.watcher")

local M = {}

---Factory function to create the appropriate Node
---nil on invalid stat or invalid link target stat
---@param args NodeArgs
---@return Node?
function M.create(args)
  if not args.fs_stat then
    return nil
  end

  if args.fs_stat.type == "directory" then
    -- directory must be readable and enumerable
    if vim.loop.fs_access(args.absolute_path, "R") and Watcher.is_fs_event_capable(args.absolute_path) then
      return DirectoryNode(args)
    end
  elseif args.fs_stat.type == "file" then
    return FileNode(args)
  elseif args.fs_stat.type == "link" then
    -- link target path and stat must resolve
    local link_to = vim.loop.fs_realpath(args.absolute_path)
    local link_to_stat = link_to and vim.loop.fs_stat(link_to)
    if not link_to or not link_to_stat then
      return
    end

    ---@cast args LinkNodeArgs
    args.link_to        = link_to
    args.fs_stat_target = link_to_stat

    -- choose directory or file
    if link_to_stat.type == "directory" then
      return DirectoryLinkNode(args)
    else
      return FileLinkNode(args)
    end
  end

  return nil
end

return M
