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
local function populate_node(node)
  -- noop if it is a file
  if node.nodes == nil then
    return
  end
  if #node.nodes == 0 then
    local cwd = node.link_to or node.absolute_path
    local handle = vim.loop.fs_scandir(cwd)
    if not handle then
      return
    end
    core.get_explorer():expand(node)
  end
end

---@param expansion_count integer
---@param node Node
---@return boolean
local function expand_until_max_or_empty(expansion_count, node)
  local should_halt = expansion_count >= M.MAX_FOLDER_DISCOVERY
  local should_exclude = M.EXCLUDE[node.name]
  return not should_halt and node.nodes and not node.open and not should_exclude
end

---@param expand_until fun(expansion_count: integer, node: Node): boolean
local function gen_iterator(expand_until)
  local expansion_count = 0
  local function expand(node)
    populate_node(node)
    node = lib.get_last_group_node(node)
    node.open = true
  end

  return function(parent)
    if parent.parent and parent.nodes and not parent.open then
      expansion_count = expansion_count + 1
      expand(parent)
    end

    Iterator.builder(parent.nodes)
      :hidden()
      :applier(function(node)
        if expand_until(expansion_count, node, populate_node) then
          expansion_count = expansion_count + 1
          expand(node)
        end
      end)
      :recursor(function(node)
        local should_recurse = expand_until(expansion_count - 1, node, populate_node)
        return expansion_count < M.MAX_FOLDER_DISCOVERY and should_recurse and node.nodes
      end)
      :iterate()

    if expansion_count >= M.MAX_FOLDER_DISCOVERY then
      return true
    end
  end
end

---@param base_node table
---@param expand_opts ApiTreeExpandAllOpts|nil
function M.fn(base_node, expand_opts)
  local expand_until = (expand_opts and expand_opts.expand_until) or expand_until_max_or_empty
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
