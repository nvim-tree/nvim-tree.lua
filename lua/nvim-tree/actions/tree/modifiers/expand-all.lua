local core = require "nvim-tree.core"
local renderer = require "nvim-tree.renderer"
local Iterator = require "nvim-tree.iterators.node-iterator"
local notify = require "nvim-tree.notify"
local lib = require "nvim-tree.lib"

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

---@param node Node
local function expand(node)
  node = lib.get_last_group_node(node)
  node.open = true
  if #node.nodes == 0 then
    core.get_explorer():expand(node)
  end
end

---@param expansion_count integer
---@param node Node
---@return boolean, function
local function expand_until_max_or_empty(expansion_count, node)
  local should_halt = expansion_count >= M.MAX_FOLDER_DISCOVERY
  local should_exclude = M.EXCLUDE[node.name]
  local result = not should_halt and node.nodes and not node.open and not should_exclude
  return result, expand_until_max_or_empty
end

local function gen_iterator(should_expand_fn)
  local expansion_count = 0

  return function(parent)
    if parent.parent and parent.nodes and not parent.open then
      expansion_count = expansion_count + 1
      expand(parent)
    end

    Iterator.builder(parent.nodes)
      :hidden()
      :applier(function(node)
        local should_expand, should_expand_next_fn = should_expand_fn(expansion_count, node)
        should_expand_fn = should_expand_next_fn
        if should_expand then
          expansion_count = expansion_count + 1
          expand(node)
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

---@param base_node table
function M.fn(base_node, expand_until)
  expand_until = expand_until or expand_until_max_or_empty
  local node = base_node.nodes and base_node or core.get_explorer()
  if gen_iterator(expand_until)(node) then
    notify.warn("expansion iteration was halted after " .. M.MAX_FOLDER_DISCOVERY .. " discovered folders")
  end
  renderer.draw()
end

function M.setup(opts)
  M.MAX_FOLDER_DISCOVERY = opts.actions.expand_all.max_folder_discovery
  M.EXCLUDE = to_lookup_table(opts.actions.expand_all.exclude)
end

return M
