local log = require("nvim-tree.log")
local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")

local M = {
  current_tab = vim.api.nvim_get_current_tabpage(),
}

function M.setup(options)
  M.options = options.actions.change_dir
end

return M
