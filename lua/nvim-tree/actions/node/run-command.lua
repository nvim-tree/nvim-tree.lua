local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")

local M = {}

---Retrieves the absolute path to the node.
---Safely handles the node representing the current directory
---(the topmost node in the nvim-tree window)
---@param node Node
---@return string
local function get_node_path(node)
  local cwd = core.get_cwd()
  if node.name == ".." and cwd then
    return utils.path_remove_trailing(cwd)
  else
    return node.absolute_path
  end
end

---@param node Node
function M.run_file_command(node)
  local node_path = get_node_path(node)
  vim.api.nvim_input(": " .. node_path .. "<Home>")
end

return M
