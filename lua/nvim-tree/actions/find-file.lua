local view = require'nvim-tree.view'
local utils = require'nvim-tree.utils'
local explorer_module = require"nvim-tree.explorer"
local git = require"nvim-tree.git"

local M = {}

local function get_explorer()
  return require"nvim-tree.lib".Tree
end

function M.fn(fname)
  local i
  local hide_root_folder = view.View.hide_root_folder
  local Explorer = get_explorer()
  if not Explorer then
    return
  end
  if Explorer.cwd == '/' or hide_root_folder then
    i = 0
  else
    i = 1
  end

  local tree_altered = false

  local function iterate_nodes(nodes)
    for _, node in ipairs(nodes) do
      i = i + 1
      if node.absolute_path == fname then
        return i
      end

      local path_matches = utils.str_find(fname, node.absolute_path..utils.path_separator)
      if path_matches then
        if #node.nodes == 0 then
          node.open = true
          explorer_module.explore(node, node.absolute_path, {})
          git.load_project_status(node.absolute_path, function(status)
            if status.dirs or status.files then
              require"nvim-tree.actions.reloaders".reload_node_status(node, git.projects)
            end
            require"nvim-tree.lib".redraw()
          end)
        end
        if node.open == false then
          node.open = true
          tree_altered = true
        end
        if iterate_nodes(node.nodes) ~= nil then
          return i
        end
      elseif node.open == true then
        iterate_nodes(node.nodes)
      end
    end
  end

  local index = iterate_nodes(Explorer.nodes)
  if tree_altered then
    require"nvim-tree.lib".redraw()
  end
  if index and view.win_open() then
    view.set_cursor({index, 0})
  end
end

return M
