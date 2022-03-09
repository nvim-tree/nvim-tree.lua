local view = require "nvim-tree.view"
local utils = require "nvim-tree.utils"
local renderer = require "nvim-tree.renderer"
local core = require "nvim-tree.core"

local M = {}

local running = {}

function M.fn(fname)
  if running[fname] or not core.get_explorer() then
    return
  end
  running[fname] = true

  local i = view.is_root_folder_visible() and 1 or 0
  local tree_altered = false

  local function iterate_nodes(nodes)
    for _, node in ipairs(nodes) do
      i = i + 1
      if node.absolute_path == fname then
        return i
      end

      local path_matches = node.nodes and vim.startswith(fname, node.absolute_path .. utils.path_separator)
      if path_matches then
        if not node.open then
          node.open = true
          tree_altered = true
        end

        if #node.nodes == 0 then
          core.get_explorer():expand(node)
        end

        if iterate_nodes(node.nodes) ~= nil then
          return i
        end
        -- mandatory to iterate i
      elseif node.open then
        iterate_nodes(node.nodes)
      end
    end
  end

  local index = iterate_nodes(core.get_explorer().nodes)
  if tree_altered then
    renderer.draw()
  end
  if index and view.is_visible() then
    view.set_cursor { index, 0 }
  end
  running[fname] = false
end

return M
