local watch = require("nvim-tree.explorer.watch")

local BaseNode = require("nvim-tree.node")

---@class (exact) LinkNode: BaseNode
---@field has_children boolean -- TODO remove this and just test nodes
---@field group_next Node|nil -- If node is grouped, this points to the next child dir/link node
---@field link_to string absolute path
local LinkNode = BaseNode:new()

---@param explorer Explorer
-----@param parent DirectoryNode    -- TODO #2871 #2886
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result|nil
---@return LinkNode
function LinkNode:new(explorer, parent, absolute_path, name, fs_stat)
  local link_to = vim.loop.fs_realpath(absolute_path)
  local open, nodes, has_children

  -- TODO-INFO: sometimes fs_realpath returns nil
  -- I expect this be a bug in glibc, because it fails to retrieve the path for some
  -- links (for instance libr2.so in /usr/lib) and thus even with a C program realpath fails
  -- when it has no real reason to. Maybe there is a reason, but errno is definitely wrong.
  -- So we need to check for link_to ~= nil when adding new links to the main tree
  local is_dir_link = (link_to ~= nil) and vim.loop.fs_stat(link_to).type == "directory"

  if is_dir_link and link_to then
    local handle = vim.loop.fs_scandir(link_to)
    has_children = handle and vim.loop.fs_scandir_next(handle) ~= nil
    open = false
    nodes = {}
  end

  local o = BaseNode.new(self, {
    type = "link",
    explorer = explorer,
    absolute_path = absolute_path,
    executable = false,
    fs_stat = fs_stat,
    hidden = false,
    is_dot = false,
    name = name,
    parent = parent,

    link_to = link_to,

    has_children = has_children,
    group_next = nil,
    nodes = nodes,
    open = open,
  })
  ---@cast o LinkNode

  if is_dir_link then
    o.watcher = watch.create_watcher(o)
  end

  return o
end

return LinkNode
