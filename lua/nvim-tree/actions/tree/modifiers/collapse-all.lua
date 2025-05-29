local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")
local Iterator = require("nvim-tree.iterators.node-iterator")

local DirectoryNode = require("nvim-tree.node.directory")

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

---@param opts ApiTreeCollapseOpts|nil
function M.fn(opts)
  opts = opts or {}
  local keep_buffers = opts.keep_buffers or false
  local under_cursor = opts.under_cursor or false

  local explorer = core.get_explorer()
  if not explorer then
    return
  end

  local node = explorer:get_node_at_cursor()
  if not node then
    return
  end

  local matches = buf_match()

  local selected_nodes
  if under_cursor then
    if not node or not node.nodes then
      return
    end
    selected_nodes = node.nodes
  else
    selected_nodes = explorer.nodes
  end

  Iterator.builder(selected_nodes)
    :hidden()
    :applier(function(n)
      local dir = n:as(DirectoryNode)
      if dir then
        dir.open = keep_buffers and matches(dir.absolute_path)
      end
    end)
    :recursor(function(n)
      return n.group_next and { n.group_next } or n.nodes
    end)
    :iterate()

  explorer.renderer:draw()
  utils.focus_node_or_parent(node)
end

return M
