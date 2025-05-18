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

---@param node Node|boolean|nil legacy -> opts.keep_buffers
---@param opts ApiTreeCollapseAllOpts|nil
function M.fn(node, opts)
  -- legacy arguments
  if type(node) == "boolean" then
    opts = {
      keep_buffers = node,
    }
    node = nil
  end
  opts = opts or {}

  local explorer = core.get_explorer()
  if not explorer then
    return
  end

  local node_at_cursor = explorer:get_node_at_cursor()
  if not node_at_cursor then
    return
  end

  local matches = buf_match()

  local nodesToIterate = explorer.nodes
  if node then
    local dir = node:as(DirectoryNode)
    if dir then
      nodesToIterate = { dir }
    end
  end

  Iterator.builder(nodesToIterate)
    :hidden()
    :applier(function(n)
      local dir = n:as(DirectoryNode)
      if dir then
        dir.open = opts.keep_buffers == true and matches(dir.absolute_path)
      end
    end)
    :recursor(function(n)
      return n.group_next and { n.group_next } or n.nodes
    end)
    :iterate()

  explorer.renderer:draw()
  utils.focus_node_or_parent(node_at_cursor)
end

return M
