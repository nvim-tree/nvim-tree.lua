local a = vim.api
local lib = function() return require'nvim-tree.lib' end
local utils = require'nvim-tree.utils'

local M = {
  current_tab = a.nvim_get_current_tabpage(),
  options = {
    global = false,
  }
}

function M.fn(name)
  if not TreeExplorer then return end

  local foldername = name == '..' and vim.fn.fnamemodify(utils.path_remove_trailing(TreeExplorer.cwd), ':h') or name
  local no_cwd_change = vim.fn.expand(foldername) == TreeExplorer.cwd
  local new_tab = a.nvim_get_current_tabpage()
  local is_window = vim.v.event.scope == "window" and new_tab == M.current_tab
  if no_cwd_change or is_window then
    return
  end
  M.current_tab = new_tab

  if M.options.global then
    vim.cmd('cd '..vim.fn.fnameescape(foldername))
  else
    vim.cmd('lcd '..vim.fn.fnameescape(foldername))
  end
  lib().init(false, foldername)
end

function M.setup(options)
  M.options.global = options.actions.change_dir.global
end

return M
