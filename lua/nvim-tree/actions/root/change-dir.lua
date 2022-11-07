local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"

local M = {
  current_tab = vim.api.nvim_get_current_tabpage(),
}

local function clean_input_cwd(name)
  name = vim.fn.fnameescape(name)
  local root_parent_cwd = vim.fn.fnamemodify(utils.path_remove_trailing(core.get_cwd()), ":h")
  if name == ".." and root_parent_cwd then
    return vim.fn.expand(root_parent_cwd)
  else
    return vim.fn.expand(name)
  end
end

local function is_window_event(new_tabpage)
  local is_event_scope_window = vim.v.event.scope == "window" or vim.v.event.changed_window
  return is_event_scope_window and new_tabpage == M.current_tab
end

local function prevent_cwd_change(foldername)
  local is_same_cwd = foldername == core.get_cwd()
  local is_restricted_above = M.options.restrict_above_cwd and foldername < vim.fn.getcwd(-1, -1)
  return is_same_cwd or is_restricted_above
end

function M.fn(input_cwd, with_open)
  if not core.get_explorer() then
    return
  end

  local new_tabpage = vim.api.nvim_get_current_tabpage()
  if is_window_event(new_tabpage) then
    return
  end

  local foldername = clean_input_cwd(input_cwd)
  if prevent_cwd_change(foldername) then
    return
  end

  M.current_tab = new_tabpage
  M.force_dirchange(foldername, with_open)
end

local function cd(global, path)
  vim.cmd((global and "cd " or "lcd ") .. vim.fn.fnameescape(path))
end

local function should_change_dir()
  return M.options.enable and vim.tbl_isempty(vim.v.event)
end

local function add_profiling_to(f)
  return function(foldername, should_open_view)
    local ps = log.profile_start("change dir %s", foldername)
    f(foldername, should_open_view)
    log.profile_end(ps, "change dir %s", foldername)
  end
end

M.force_dirchange = add_profiling_to(function(foldername, should_open_view)
  if should_change_dir() then
    cd(M.options.global, foldername)
  end

  core.init(foldername)

  if should_open_view then
    require("nvim-tree.lib").open()
  else
    require("nvim-tree.renderer").draw()
  end
end)

function M.setup(options)
  M.options = options.actions.change_dir
end

return M
