local view = require'nvim-tree.view'
local utils = require'nvim-tree.utils'
local explorer_module = require"nvim-tree.explorer"
local git = require"nvim-tree.git"
local renderer = require"nvim-tree.renderer"

local M = {}

local function get_index_offset()
  local hide_root_folder = view.View.hide_root_folder
  if TreeExplorer.cwd == '/' or hide_root_folder then
    return 0
  else
    return 1
  end
end

function M.fn(fname)
  if not TreeExplorer then return end

  local i = get_index_offset()
  local tree_altered = false

  local function iterate_nodes(nodes)
    for _, node in ipairs(nodes) do
      i = i + 1
      if node.absolute_path == fname then
        return i
      end

      local path_matches = node.nodes and utils.str_find(fname, node.absolute_path..utils.path_separator)
      if path_matches then
        if not node.open then
          node.open = true
          tree_altered = true
        end

        if #node.nodes == 0 then
          local git_finished = false
          git.load_project_status(node.absolute_path, function(status)
            explorer_module.explore(node, node.absolute_path, status)
            git_finished = true
          end)
          while not vim.wait(10, function() return git_finished end, 10) do end
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

  local index = iterate_nodes(TreeExplorer.nodes)
  if tree_altered then
    renderer.draw()
  end
  if index and view.is_visible() then
    view.set_cursor({index, 0})
  end
end

return M
