local watch = require("nvim-tree.explorer.watch")

local BaseNode = require("nvim-tree.node")

---@class (exact) LinkNode: BaseNode
---@field has_children boolean
---@field group_next Node? -- If node is grouped, this points to the next child dir/link node
---@field link_to string absolute path
---@field nodes Node[]
---@field open boolean
local LinkNode = BaseNode:new()

---Static factory method
---@param explorer Explorer
---@param parent Node
---@param absolute_path string
---@param name string
---@param fs_stat uv.fs_stat.result?
---@return LinkNode? nil on vim.loop.fs_realpath failure
function LinkNode:create(explorer, parent, absolute_path, name, fs_stat)
  -- INFO: sometimes fs_realpath returns nil
  -- I expect this be a bug in glibc, because it fails to retrieve the path for some
  -- links (for instance libr2.so in /usr/lib) and thus even with a C program realpath fails
  -- when it has no real reason to. Maybe there is a reason, but errno is definitely wrong.
  local link_to = vim.loop.fs_realpath(absolute_path)
  if not link_to then
    return nil
  end

  local open, nodes, has_children
  local is_dir_link = (link_to ~= nil) and vim.loop.fs_stat(link_to).type == "directory"

  if is_dir_link and link_to then
    local handle = vim.loop.fs_scandir(link_to)
    has_children = handle and vim.loop.fs_scandir_next(handle) ~= nil or false
    open = false
    nodes = {}
  end

  ---@type LinkNode
  local o = {
    type = "link",
    explorer = explorer,
    absolute_path = absolute_path,
    executable = false,
    fs_stat = fs_stat,
    hidden = false,
    is_dot = false,
    name = name,
    parent = parent,
    watcher = nil,
    diag_status = nil,

    has_children = has_children,
    group_next = nil,
    link_to = link_to,
    nodes = nodes,
    open = open,
  }
  o = self:new(o) --[[@as LinkNode]]

  if is_dir_link then
    o.watcher = watch.create_watcher(o)
  end

  return o
end

return LinkNode
