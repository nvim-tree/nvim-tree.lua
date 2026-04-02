local notify = require("nvim-tree.notify")

local M = {}

---@param node Node
function M.fn(node)
  local _, err = vim.ui.open(node.link_to or node.absolute_path)

  -- err only provided on opener executable not found hence logging path is not useful
  if err then
    notify.warn(err)
  end
end

return M
