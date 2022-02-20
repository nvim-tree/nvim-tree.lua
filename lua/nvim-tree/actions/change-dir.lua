local a = vim.api
local utils = require'nvim-tree.utils'

local M = {
  current_tab = a.nvim_get_current_tabpage(),
  options = {
    global = false,
  }
}

function M.fn(name, with_open)
  if not TreeExplorer then return end

  local foldername = name == '..' and vim.fn.fnamemodify(utils.path_remove_trailing(TreeExplorer.cwd), ':h') or name
  local no_cwd_change = vim.fn.expand(foldername) == TreeExplorer.cwd
  local new_tab = a.nvim_get_current_tabpage()
  local is_window = (vim.v.event.scope == "window" or vim.v.event.changed_window) and new_tab == M.current_tab
  if no_cwd_change or is_window then
    return
  end
  M.current_tab = new_tab
  M.force_dirchange(foldername, with_open)
end

function M.force_dirchange(foldername, with_open)
  if vim.tbl_isempty(vim.v.event) then
    if M.options.global then
      vim.cmd('cd '..vim.fn.fnameescape(foldername))
    else
      vim.cmd('lcd '..vim.fn.fnameescape(foldername))
    end
  end
  require'nvim-tree.lib'.init(foldername)
  if with_open then
    require"nvim-tree.lib".open()
  else
    require"nvim-tree.renderer".draw()
  end
end

function M.setup(options)
  M.options.global = options.actions.change_dir.global
end

return M
