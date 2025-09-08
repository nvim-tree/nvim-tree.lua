local core = require("nvim-tree.core")
local Iterator = require("nvim-tree.iterators.node-iterator")

local M = {}

---@param direction string
---@return fun(node: Node): nil
function M.fn(direction)
  return function(node)
    if node.name == ".." or not direction then
      return
    end

    local explorer = core.get_explorer()
    if not explorer then
      return
    end

    local first, last, next, prev = nil, nil, nil, nil
    local found = false
    local parent = node.parent or explorer
    Iterator.builder(parent and parent.nodes or {})
      :recursor(function()
        return nil
      end)
      :applier(function(n)
        first = first or n
        last = n
        if n.absolute_path == node.absolute_path then
          found = true
          return
        end
        prev = not found and n or prev
        if found and not next then
          next = n
        end
      end)
      :iterate()

    local target_node
    if direction == "first" then
      target_node = first
    elseif direction == "last" then
      target_node = last
    elseif direction == "next" then
      target_node = next or first
    else
      target_node = prev or last
    end

    if target_node then
      explorer:focus_node_or_parent(target_node)
    end
  end
end

return M
