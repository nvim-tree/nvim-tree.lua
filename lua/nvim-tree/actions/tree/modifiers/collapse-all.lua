local renderer = require "nvim-tree.renderer"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local lib = require "nvim-tree.lib"
local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {}

---@return fun(path: string): boolean
local function buf_match()
  local buffer_paths = vim.tbl_map(function(buffer)
    return vim.api.nvim_buf_get_name(buffer)
  end, vim.api.nvim_list_bufs())

  return function(path)
    for _, buffer_path in ipairs(buffer_paths) do
      local matches = utils.str_find(buffer_path, path)
      if matches then
        return true
      end
    end
    return false
  end
end

---@param keep_buffers boolean
function M.fn(keep_buffers)
  local node = lib.get_node_at_cursor()
  local explorer = core.get_explorer()

  if explorer == nil then
    return
  end

  local matches = buf_match()

  Iterator.builder(explorer.nodes)
    :hidden()
    :applier(function(n)
      if n.nodes ~= nil then
        n.open = keep_buffers == true and matches(n.absolute_path)
      end
    end)
    :recursor(function(n)
      return n.group_next and { n.group_next } or n.nodes
    end)
    :iterate()

  renderer.draw()
  utils.focus_node_or_parent(node)
end

return M
