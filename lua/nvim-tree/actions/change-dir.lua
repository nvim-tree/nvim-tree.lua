local a = vim.api
local lib = function() return require'nvim-tree.lib' end

local M = {
  current_tab = a.nvim_get_current_tabpage(),
  options = {
    global = false,
  }
}

function M.fn(name)
  local foldername = name == '..' and vim.fn.fnamemodify(lib().Tree.cwd, ':h') or name
  local no_cwd_change = vim.fn.expand(foldername) == lib().Tree.cwd
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
  if options.actions.change_dir.global ~= nil then
    M.options.global = options.actions.change_dir.global
  else
    M.options.global = vim.g.nvim_tree_change_dir_global == 1
  end
end

return M
