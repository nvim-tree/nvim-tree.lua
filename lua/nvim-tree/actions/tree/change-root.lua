local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")
local config = require("nvim-tree.config")

local M = {}

--- Update the tree root to a directory or the directory containing
---@param path string relative or absolute
---@param bufnr number|nil
function M.fn(path, bufnr)
  -- skip if current file is in ignore_list
  if type(bufnr) == "number" then
    local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr }) or ""

    for _, value in pairs(config.g.update_focused_file.update_root.ignore_list) do
      if utils.str_find(path, value) or utils.str_find(ft, value) then
        return
      end
    end
  end

  -- don't find inexistent
  if vim.fn.filereadable(path) == 0 then
    return
  end

  local cwd = core.get_cwd()
  if cwd == nil then
    return
  end

  local vim_cwd = vim.fn.getcwd()

  local explorer = core.get_explorer()
  if not explorer then
    return
  end

  -- test if in vim_cwd
  if utils.path_relative(path, vim_cwd) ~= path then
    if vim_cwd ~= cwd then
      explorer:change_dir(vim_cwd)
    end
    return
  end
  -- test if in cwd
  if utils.path_relative(path, cwd) ~= path then
    return
  end

  -- otherwise test init_root
  if config.g.prefer_startup_root and utils.path_relative(path, config.init_root) ~= path then
    explorer:change_dir(config.init_root)
    return
  end
  -- otherwise root_dirs
  for _, dir in pairs(config.g.root_dirs) do
    dir = vim.fn.fnamemodify(dir, ":p")
    if utils.path_relative(path, dir) ~= path then
      explorer:change_dir(dir)
      return
    end
  end
  -- finally fall back to the folder containing the file
  explorer:change_dir(vim.fn.fnamemodify(path, ":p:h"))
end

return M
