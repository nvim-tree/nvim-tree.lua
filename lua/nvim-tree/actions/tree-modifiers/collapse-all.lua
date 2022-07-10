local renderer = require "nvim-tree.renderer"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {}

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

function M.fn(keep_buffers)
  if not core.get_explorer() then
    return
  end

  local matches = buf_match()

  Iterator.builder(core.get_explorer().nodes)
    :hidden()
    :applier(function(node)
      node.open = keep_buffers == true and matches(node.absolute_path)
    end)
    :recursor(function(n)
      return n.nodes
    end)
    :iterate()

  renderer.draw()
end

return M
