local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local core = require "nvim-tree.core"
local lib = require "nvim-tree.lib"
local explorer_node = require "nvim-tree.explorer.node"

local M = {}

---@class NavigationItemOpts
---@field where string
---@field what string

---@param opts NavigationItemOpts
---@return fun()
function M.fn(opts)
  return function()
    local node_cur = lib.get_node_at_cursor()
    local first_node_line = core.get_nodes_starting_line()
    local nodes_by_line = utils.get_nodes_by_line(core.get_explorer().nodes, first_node_line)
    local iter_start, iter_end, iter_step, cur, first, nex

    if opts.where == "next" then
      iter_start, iter_end, iter_step = first_node_line, #nodes_by_line, 1
    elseif opts.where == "prev" then
      iter_start, iter_end, iter_step = #nodes_by_line, first_node_line, -1
    end

    for line = iter_start, iter_end, iter_step do
      local node = nodes_by_line[line]
      local valid = false

      if opts.what == "git" then
        local git_status = explorer_node.get_git_status(node)
        valid = git_status ~= nil and (not opts.skip_gitignored or git_status[1] ~= "!!")
      elseif opts.what == "diag" then
        valid = node.diag_status ~= nil
      elseif opts.what == "opened" then
        valid = vim.fn.bufloaded(node.absolute_path) ~= 0
      end

      if not first and valid then
        first = line
      end

      if node == node_cur then
        cur = line
      elseif valid and cur then
        nex = line
        break
      end
    end

    if nex then
      view.set_cursor { nex, 0 }
    elseif vim.o.wrapscan and first then
      view.set_cursor { first, 0 }
    end
  end
end

return M
