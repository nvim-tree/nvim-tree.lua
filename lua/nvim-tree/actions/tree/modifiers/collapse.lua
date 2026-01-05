local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")
local Iterator = require("nvim-tree.iterators.node-iterator")

local FileNode = require("nvim-tree.node.file")
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

---Collapse a node, root if nil
---@param node Node?
---@param opts ApiCollapseOpts
local function collapse(node, opts)
  local explorer = core.get_explorer()
  if not explorer then
    return
  end

  node = node or explorer

  local node_at_cursor = explorer:get_node_at_cursor()
  if not node_at_cursor then
    return
  end

  local matches = buf_match()

  Iterator.builder({ node:is(FileNode) and node.parent or node:as(DirectoryNode) })
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
  explorer:focus_node_or_parent(node_at_cursor)
end


---@param opts ApiCollapseOpts|boolean|nil legacy -> opts.keep_buffers
function M.all(opts)
  -- legacy arguments
  if type(opts) == "boolean" then
    opts = {
      keep_buffers = opts,
    }
  end

  collapse(nil, opts or {})
end

---@param node Node
---@param opts ApiCollapseOpts?
function M.node(node, opts)
  collapse(node, opts or {})
end

return M
