local core = require("nvim-tree.core")
local config = require("nvim-tree.config")
local find_file = require("nvim-tree.actions.tree.find-file")

local M = {}

---@param name? string
function M.fn(name)
  local explorer = core.get_explorer()
  if name and explorer then
    explorer:change_dir(name)
  end

  if config.g.update_focused_file.update_root.enable then
    find_file.fn()
  end
end

return M
