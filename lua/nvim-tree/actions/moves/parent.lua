local renderer = require "nvim-tree.renderer"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local lib = require "nvim-tree.lib"

local M = {}

---@param should_close boolean|nil
---@return fun(node: Node): boolean|nil
function M.fn(should_close)
  should_close = should_close or false

  return function(node)
    node = lib.get_last_group_node(node)
    if should_close and node.open then
      node.open = false
      return renderer.draw()
    end

    local parent = utils.get_parent_of_group(node).parent

    if not parent or not parent.parent then
      local explorer = core.get_explorer()
      if explorer then
        return explorer.view:set_cursor { 1, 0 }
      end
    end

    local _, line = utils.find_node(core.get_explorer().nodes, function(n)
      return n.absolute_path == parent.absolute_path
    end)

    local explorer = core.get_explorer()
    if explorer then
      explorer.view:set_cursor { line + 1, 0 }
    end
    if should_close then
      parent.open = false
      renderer.draw()
    end
  end
end

return M
