local view = require("nvim-tree.view")
local DirectoryNode = require("nvim-tree.node.directory")

local M = {}

---@param should_close boolean|nil
---@return fun(node: Node): boolean|nil
function M.fn(should_close)
  should_close = should_close or false

  ---@param node Node
  return function(node)
    local dir = node:as(DirectoryNode)
    if dir then
      dir = dir:last_group_node()
      if should_close and dir.open then
        dir.open = false
        dir.explorer.renderer:draw()
        return
      end
    end

    local parent = (node:get_parent_of_group() or node).parent

    if not parent or not parent.parent then
      view.set_cursor({ 1, 0 })
      return
    end

    local _, line = parent.explorer:find_node(function(n)
      return n.absolute_path == parent.absolute_path
    end)

    view.set_cursor({ line + 1, 0 })
    if should_close then
      parent.open = false
      parent.explorer.renderer:draw()
    end
  end
end

return M
