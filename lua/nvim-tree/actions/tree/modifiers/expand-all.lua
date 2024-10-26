local core = require("nvim-tree.core")
local Iterator = require("nvim-tree.iterators.node-iterator")
local notify = require("nvim-tree.notify")

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

---@param expansion_count integer
---@param node Node
---@return boolean
local function should_expand(expansion_count, node)
  local dir = node:as(DirectoryNode)
  if not dir then
    return false
  end
  local should_halt = expansion_count >= M.MAX_FOLDER_DISCOVERY
  local should_exclude = M.EXCLUDE[dir.name]
  return not should_halt and not dir.open and not should_exclude
end

local function gen_iterator()
  local expansion_count = 0

  return function(parent)
    if parent.parent and parent.nodes and not parent.open then
      expansion_count = expansion_count + 1
      expand(parent)
    end

    Iterator.builder(parent.nodes)
      :hidden()
      :applier(function(node)
        if should_expand(expansion_count, node) then
          expansion_count = expansion_count + 1
          node = node:as(DirectoryNode)
          if node then
            expand(node)
          end
        end
      end)
      :recursor(function(node)
        return expansion_count < M.MAX_FOLDER_DISCOVERY and (node.group_next and { node.group_next } or (node.open and node.nodes))
      end)
      :iterate()

    if expansion_count >= M.MAX_FOLDER_DISCOVERY then
      return true
    end
  end
end

---Expand the directory node or the root
---@param node Node
function M.fn(node)
  local explorer = core.get_explorer()
  local parent = node:as(DirectoryNode) or explorer
  if not parent then
    return
  end

  if gen_iterator()(parent) then
    notify.warn("expansion iteration was halted after " .. M.MAX_FOLDER_DISCOVERY .. " discovered folders")
  end
  if explorer then
    explorer.renderer:draw()
  end
end

function M.setup(opts)
  M.MAX_FOLDER_DISCOVERY = opts.actions.expand_all.max_folder_discovery
  M.EXCLUDE = to_lookup_table(opts.actions.expand_all.exclude)
end

return M
