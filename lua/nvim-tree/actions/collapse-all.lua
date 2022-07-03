local renderer = require "nvim-tree.renderer"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {}

function M.fn(keep_buffers)
  if not core.get_explorer() then
    return
  end

  local buffer_paths = vim.tbl_map(function(buffer)
    return vim.api.nvim_buf_get_name(buffer)
  end, vim.api.nvim_list_bufs())

  Iterator.builder(core.get_explorer().nodes)
    :hidden()
    :applier(function(node)
      node.open = false
      if keep_buffers == true then
        for _, buffer_path in ipairs(buffer_paths) do
          local matches = utils.str_find(buffer_path, node.absolute_path)
          if matches then
            node.open = true
            return
          end
        end
      end
    end)
    :recursor(function(n)
      return n.nodes
    end)
    :iterate()

  renderer.draw()
end

return M
