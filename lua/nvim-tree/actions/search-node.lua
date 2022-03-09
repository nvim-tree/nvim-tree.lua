local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local renderer = require "nvim-tree.renderer"

local M = {}

function M.fn()
  if not TreeExplorer then
    return
  end

  local input_path = vim.fn.input("Search node: ", "", "file")
  utils.clear_prompt()

  local absolute_input_path = utils.path_join {
    TreeExplorer.cwd,
    input_path,
  }

  local function count_visible_nodes(nodes)
    local visible_nodes = 0
    for _, node in ipairs(nodes) do
      visible_nodes = visible_nodes + 1

      if node.open and node.nodes then
        visible_nodes = visible_nodes + count_visible_nodes(node.nodes)
      end
    end

    return visible_nodes
  end

  local tree_altered = false
  local found_something = false

  local function search_node(nodes)
    local index = 0

    for _, node in ipairs(nodes) do
      index = index + 1

      if absolute_input_path == node.absolute_path then
        found_something = true
        return index
      end

      if node.nodes then
        -- e.g. user searches for "/foo/bar.txt", than directory "/foo/bar" should not match with filename
        local matches = utils.str_find(absolute_input_path, node.absolute_path .. "/")

        if matches then
          found_something = true

          -- if node is not open -> open it
          if not node.open then
            node.open = true
            TreeExplorer:expand(node)
            tree_altered = true
          end

          return index + search_node(node.nodes)
        end
      end

      if node.open then
        index = index + count_visible_nodes(node.nodes)
      end
    end

    return index
  end

  local index = search_node(TreeExplorer.nodes)

  if tree_altered then
    renderer.draw()
  end

  if found_something and view.is_visible() then
    if view.is_root_folder_visible() then
      index = index + 1
    end

    view.set_cursor { index, 0 }
  end
end

return M
