local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local renderer = require "nvim-tree.renderer"
local core = require "nvim-tree.core"
local lib = require "nvim-tree.lib"

local M = {}

local function get_index_of(node, nodes)
  local node_path = node.absolute_path
  local line = 1

  for _, _node in ipairs(nodes) do
    if not _node.hidden then
      local n = lib.get_last_group_node(_node)
      if node_path == n.absolute_path then
        return line
      end

      line = line + 1
    end
  end
end

function M.parent_node(should_close)
  should_close = should_close or false

  return function(node)
    if should_close and node.open then
      node.open = false
      return renderer.draw()
    end

    local parent = node.parent

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

function M.sibling(direction)
  return function(node)
    if node.name == ".." or not direction then
      return
    end

    local parent = node.parent or core.get_explorer()
    local parent_nodes = vim.tbl_filter(function(n)
      return not n.hidden
    end, parent.nodes)

    local node_index = get_index_of(node, parent_nodes)

    local target_idx = node_index + direction
    if target_idx < 1 then
      target_idx = 1
    elseif target_idx > #parent_nodes then
      target_idx = #parent_nodes
    end

    local target_node = parent_nodes[target_idx]
    local _, line = utils.find_node(core.get_explorer().nodes, function(n)
      return n.absolute_path == target_node.absolute_path
    end)

    view.set_cursor { line + 1, 0 }
  end
end

function M.find_git_item(where)
  return function()
    local node_cur = lib.get_node_at_cursor()
    local nodes_by_line = utils.get_nodes_by_line(core.get_explorer().nodes, core.get_nodes_starting_line())

    local cur, first, prev, nex = nil, nil, nil, nil
    for line, node in pairs(nodes_by_line) do
      if not first and node.git_status then
        first = line
      end

      if node == node_cur then
        cur = line
      elseif node.git_status then
        if not cur then
          prev = line
        end
        if cur and not nex then
          nex = line
          break
        end
      end
    end

    if where == "prev" then
      if prev then
        view.set_cursor { prev, 0 }
      end
    else
      if cur then
        if nex then
          view.set_cursor { nex, 0 }
        end
      elseif first then
        view.set_cursor { first, 0 }
      end
    end
  end
end

return M
