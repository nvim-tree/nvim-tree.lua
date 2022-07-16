local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local core = require "nvim-tree.core"
local lib = require "nvim-tree.lib"

local M = {}

function M.fn(where, what)
  return function()
    local node_cur = lib.get_node_at_cursor()
    local nodes_by_line = utils.get_nodes_by_line(core.get_explorer().nodes, core.get_nodes_starting_line())

    local cur, first, prev, nex = nil, nil, nil, nil
    for line, node in pairs(nodes_by_line) do
      local valid = false
      if what == "git" then
        valid = node.git_status ~= nil
      elseif what == "diag" then
        valid = node.diag_status ~= nil
      end

      if not first and valid then
        first = line
      end

      if node == node_cur then
        cur = line
      elseif valid then
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
