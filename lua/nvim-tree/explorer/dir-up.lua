local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")

local M = {}

function M.fn(node)
  if not node or node.name == ".." then
    require("lua.nvim-tree.explorer.change-dir").fn("..")
  else
    local cwd = core.get_cwd()
    if cwd == nil then
      return
    end

    local newdir = vim.fn.fnamemodify(utils.path_remove_trailing(cwd), ":h")
    require("lua.nvim-tree.explorer.change-dir").fn(newdir)
    require("nvim-tree.actions.finders.find-file").fn(node.absolute_path)
  end
end

return M
