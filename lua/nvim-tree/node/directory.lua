local watch = require("nvim-tree.explorer.watch")

local BaseNode = require("nvim-tree.node")

---@class (exact) DirectoryNode: BaseNode
---@field has_children boolean
---@field group_next Node? -- If node is grouped, this points to the next child dir/link node
---@field nodes Node[]
---@field open boolean
---@field hidden_stats table? -- Each field of this table is a key for source and value for count
local DirectoryNode = BaseNode:new()

---Static factory method
---@param explorer Explorer
---@param parent Node?
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result|nil
---@return DirectoryNode
function DirectoryNode:create(explorer, parent, absolute_path, name, fs_stat)
  local handle = vim.loop.fs_scandir(absolute_path)
  local has_children = handle and vim.loop.fs_scandir_next(handle) ~= nil or false

  ---@type DirectoryNode
  local o = {
    type = "directory",
    explorer = explorer,
    absolute_path = absolute_path,
    executable = false,
    fs_stat = fs_stat,
    git_status = nil,
    hidden = false,
    is_dot = false,
    name = name,
    parent = parent,
    watcher = nil,
    diag_status = nil,

    has_children = has_children,
    group_next = nil,
    nodes = {},
    open = false,
    hidden_stats = nil,
  }
  o = self:new(o) --[[@as DirectoryNode]]

  o.watcher = watch.create_watcher(o)

  return o
end

return DirectoryNode
