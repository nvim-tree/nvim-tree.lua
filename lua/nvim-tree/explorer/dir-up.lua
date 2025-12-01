local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")
local change_dir = require("nvim-tree.explorer.change-dir")
local find_file = require("nvim-tree.actions.finders.find-file")

local M = {}

function M.fn(node)
  if not node or node.name == ".." then
    change_dir.fn("..")
  else
    local cwd = core.get_cwd()
    if cwd == nil then
      return
    end

    local newdir = vim.fn.fnamemodify(utils.path_remove_trailing(cwd), ":h")
    change_dir.fn(newdir)
    find_file.fn(node.absolute_path)
  end
end

return M
