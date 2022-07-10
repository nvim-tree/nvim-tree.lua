local renderer = require "nvim-tree.renderer"
local view = require "nvim-tree.view"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"

local M = {}

function M.fn(should_close)
  should_close = should_close or false

  return function(node)
    if should_close and node.open then
      node.open = false
      return renderer.draw()
    end

    local parent = node.parent

    if renderer.config.group_empty and parent then
      while parent.parent and parent.parent.group_next do
        parent = parent.parent
      end
    end

    if not parent or not parent.parent then
      return view.set_cursor { 1, 0 }
    end

    local _, line = utils.find_node(core.get_explorer().nodes, function(n)
      return n.absolute_path == parent.absolute_path
    end)

    view.set_cursor { line + 1, 0 }
    if should_close then
      parent.open = false
      renderer.draw()
    end
  end
end

return M
