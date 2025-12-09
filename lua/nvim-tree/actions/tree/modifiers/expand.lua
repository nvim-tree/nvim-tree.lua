local core = require("nvim-tree.core")
local Iterator = require("nvim-tree.iterators.node-iterator")
local notify = require("nvim-tree.notify")

local FileNode = require("nvim-tree.node.file")
local DirectoryNode = require("nvim-tree.node.directory")

local M = {}

---@param list string[]
---@return table
local function to_lookup_table(list)
  local table = {}
  for _, element in ipairs(list) do
    table[element] = true
  end

  return table
end

---@param node DirectoryNode
local function expand(node)
  node = node:last_group_node()
  node.open = true
  if #node.nodes == 0 then
    core.get_explorer():expand(node)
  end
end

---@param should_descend fun(expansion_count: integer, node: Node): boolean
---@return fun(expansion_count: integer, node: Node): boolean
local function limit_folder_discovery(should_descend)
  return function(expansion_count, node)
    local should_halt = expansion_count >= M.MAX_FOLDER_DISCOVERY
    if should_halt then
      notify.warn("expansion iteration was halted after " .. M.MAX_FOLDER_DISCOVERY .. " discovered folders")
      return false
    end

    return should_descend(expansion_count, node)
  end
end

---@param _ integer expansion_count
---@param node Node
---@return boolean
local function descend_until_empty(_, node)
  local dir = node:as(DirectoryNode)
  if not dir then
    return false
  end

  local should_exclude = M.EXCLUDE[dir.name]
  return not should_exclude
end

---@param expansion_count integer
---@param node Node
---@param should_descend fun(expansion_count: integer, node: Node): boolean
---@return boolean
local function should_expand(expansion_count, node, should_descend)
  local dir = node:as(DirectoryNode)
  if not dir then
    return false
  end

  if not dir.open and should_descend(expansion_count, node) then
    if #node.nodes == 0 then
      core.get_explorer():expand(dir) -- populate node.group_next
    end

    if dir.group_next then
      local expand_next = should_expand(expansion_count, dir.group_next, should_descend)
      if expand_next then
        dir.open = true
      end
      return expand_next
    else
      return true
    end
  end
  return false
end


---@param should_descend fun(expansion_count: integer, node: Node): boolean
---@return fun(node): any
local function gen_iterator(should_descend)
  local expansion_count = 0

  return function(parent)
    if parent.parent and parent.nodes and not parent.open then
      expansion_count = expansion_count + 1
      expand(parent)
    end

    Iterator.builder(parent.nodes)
      :hidden()
      :applier(function(node)
        if should_expand(expansion_count, node, should_descend) then
          expansion_count = expansion_count + 1
          node = node:as(DirectoryNode)
          if node then
            expand(node)
          end
        end
      end)
      :recursor(function(node)
        if not should_descend(expansion_count, node) then
          return nil
        end

        if node.group_next then
          return { node.group_next }
        end

        if node.open and node.nodes then
          return node.nodes
        end

        return nil
      end)
      :iterate()
  end
end

---@param node Node?
---@param expand_opts ApiTreeExpandOpts?
local function expand_node(node, expand_opts)
  if not node then
    return
  end
  local descend_until = limit_folder_discovery((expand_opts and expand_opts.expand_until) or descend_until_empty)
  gen_iterator(descend_until)(node)

  local explorer = core.get_explorer()
  if explorer then
    explorer.renderer:draw()
  end
end

---Expand the directory node or the root
---@param node Node
---@param expand_opts ApiTreeExpandOpts?
function M.all(node, expand_opts)
  expand_node(node and node:as(DirectoryNode) or core.get_explorer(), expand_opts)
end

---Expand the directory node or parent node
---@param node Node
---@param expand_opts ApiTreeExpandOpts?
function M.node(node, expand_opts)
  if not node then
    return
  end

  expand_node(node:is(FileNode) and node.parent or node:as(DirectoryNode), expand_opts)
end

function M.setup(opts)
  M.MAX_FOLDER_DISCOVERY = opts.actions.expand_all.max_folder_discovery
  M.EXCLUDE = to_lookup_table(opts.actions.expand_all.exclude)
end

return M
