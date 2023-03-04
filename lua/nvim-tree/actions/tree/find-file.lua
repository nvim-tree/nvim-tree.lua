local core = require "nvim-tree.core"
local utils = require "nvim-tree.utils"
local open = require "nvim-tree.actions.tree.open"

local M = {}

local function is_file_readable(fname)
  local stat = vim.loop.fs_stat(fname)
  return stat and stat.type == "file" and vim.loop.fs_access(fname, "R")
end

local function change_dir(name)
  change_dir.fn(name)

  if M.config.update_focused_file.enable then
    M.fn(false)
  end
end

local function change_root(filepath, bufnr)
  -- skip if current file is in ignore_list
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype") or ""
  for _, value in pairs(M.config.update_focused_file.ignore_list) do
    if utils.str_find(filepath, value) or utils.str_find(ft, value) then
      return
    end
  end

  local cwd = core.get_cwd()
  local vim_cwd = vim.fn.getcwd()

  -- test if in vim_cwd
  if utils.path_relative(filepath, vim_cwd) ~= filepath then
    if vim_cwd ~= cwd then
      change_dir.fn(vim_cwd)
    end
    return
  end
  -- test if in cwd
  if utils.path_relative(filepath, cwd) ~= filepath then
    return
  end

  -- otherwise test M.init_root
  if M.config.prefer_startup_root and utils.path_relative(filepath, M.init_root) ~= filepath then
    change_dir.fn(M.init_root)
    return
  end
  -- otherwise root_dirs
  for _, dir in pairs(M.config.root_dirs) do
    dir = vim.fn.fnamemodify(dir, ":p")
    if utils.path_relative(filepath, dir) ~= filepath then
      change_dir.fn(dir)
      return
    end
  end
  -- finally fall back to the folder containing the file
  change_dir.fn(vim.fn.fnamemodify(filepath, ":p:h"))
end

function M.fn(with_open, bufnr, bang)
  if not with_open and not core.get_explorer() then
    return
  end

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local filepath = utils.canonical_path(vim.fn.fnamemodify(bufname, ":p"))
  if not is_file_readable(filepath) then
    return
  end

  if with_open then
    open.fn()
  end

  if bang or M.config.update_focused_file.update_root then
    change_root(filepath, bufnr)
  end

  require("nvim-tree.actions.finders.find-file").fn(filepath)
end

function M.setup(opts)
  M.config = opts or {}
end

return M
