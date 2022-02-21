local utils = require'nvim-tree.utils'
local git = require"nvim-tree.git"
local renderer = require'nvim-tree.renderer'

local M = {}

function M.fn()
  if not TreeExplorer then return end

  local input_path = vim.fn.input("Search node: ", "", "file")
  utils.clear_prompt()

  local absolute_input_path = TreeExplorer.cwd .. utils.path_separator .. input_path

  local function search_node(nodes)
    for _, node in ipairs(nodes) do
      local matches = utils.str_find(absolute_input_path, node.absolute_path)
      if matches and node.nodes then
        if not node.open then
          node.open = true
          TreeExplorer:expand(node)
        end
        search_node(node.nodes)
      end
    end
  end

  node = search_node(TreeExplorer.nodes)
end

return M

