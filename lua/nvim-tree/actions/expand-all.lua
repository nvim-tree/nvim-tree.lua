local core = require "nvim-tree.core"
local renderer = require "nvim-tree.renderer"
local utils = require "nvim-tree.utils"

local M = {}

local function expand(node)
  node.open = true
  if #node.nodes == 0 then
    core.get_explorer():expand(node)
  end
end

local function gen_iterator()
  local expansion_count = 0

  local function iterate(parent)
    if expansion_count >= M.MAX_FOLDER_DISCOVERY then
      return true
    end

    if parent.parent and parent.nodes and not parent.open then
      expansion_count = expansion_count + 1
      expand(parent)
    end

    for _, node in pairs(parent.nodes) do
      if node.nodes and not node.open then
        expansion_count = expansion_count + 1
        expand(node)
      end

      if node.open then
        if iterate(node) then
          return true
        end
      end
    end
  end

  return iterate
end

function M.fn(base_node)
  local node = base_node.nodes and base_node or core.get_explorer()
  if gen_iterator()(node) then
    utils.warn("expansion iteration was halted after " .. M.MAX_FOLDER_DISCOVERY .. " discovered folders")
  end
  renderer.draw()
end

function M.setup(opts)
  M.MAX_FOLDER_DISCOVERY = opts.actions.expand_all.max_folder_discovery
end

return M
