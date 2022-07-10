local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
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

function M.fn(direction)
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

return M
