local utils = require"nvim-tree.utils"
local view = require"nvim-tree.view"
local renderer = require"nvim-tree.renderer"

local M = {}

function M.fn()
  if not TreeExplorer then return end

  local input_path = vim.fn.input("Search node: ", "", "file")
  utils.clear_prompt()

  local absolute_input_path = utils.path_join({
    TreeExplorer.cwd,
    input_path
  })

  local tree_altered = false

  local function search_node(nodes)
    -- first search for absolute match
    local index_absolute_match = 0
    for _, node in ipairs(nodes) do
      index_absolute_match = index_absolute_match + 1

      if absolute_input_path == node.absolute_path then
        return index_absolute_match
      end
    end

    -- if no absolute match in current directory, then search for partial match
    local index_partial_match = 0
    for _, node in ipairs(nodes) do
      index_partial_match = index_partial_match + 1

      if node.nodes then
        local matches = utils.str_find(absolute_input_path, node.absolute_path)

        if matches then
          if not node.open then
            node.open = true
            TreeExplorer:expand(node)
            tree_altered = true
          end

          return index_partial_match + search_node(node.nodes)
        end
      end
    end

    return 0
  end

  local index = search_node(TreeExplorer.nodes)

  if tree_altered then
    renderer.draw()
  end

  if index > 0 and view.is_visible() then
    if TreeExplorer.cwd ~= '/' and not view.View.hide_root_folder then
      index = index + 1
    end

    view.set_cursor({index, 0})
  end
end

return M
