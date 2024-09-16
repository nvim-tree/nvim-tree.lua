local watch = require("nvim-tree.explorer.watch")

local BaseNode = require("nvim-tree.node")

---@class (exact) DirectoryNode: BaseNode
---@field has_children boolean
---@field group_next Node|nil
---@field nodes Node[]
---@field open boolean
---@field hidden_stats table -- Each field of this table is a key for source and value for count
local DirectoryNode = BaseNode:new()

---@param explorer Explorer
-----@param parent DirectoryNode    -- TODO  #2871 #2886
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result|nil
---@return DirectoryNode
function DirectoryNode:new(explorer, parent, absolute_path, name, fs_stat)
  local handle = vim.loop.fs_scandir(absolute_path)
  local has_children = handle and vim.loop.fs_scandir_next(handle) ~= nil

  local o = BaseNode.new(self, {
    type = "directory",
    explorer = explorer,
    absolute_path = absolute_path,
    executable = false,
    fs_stat = fs_stat,
    hidden = false,
    is_dot = false,
    name = name,
    parent = parent,

    has_children = has_children,
    group_next = nil, -- If node is grouped, this points to the next child dir/link node
    nodes = {},
    open = false,
  })
  ---@cast o DirectoryNode

  o.watcher = watch.create_watcher(o)

  return o
end

return DirectoryNode
