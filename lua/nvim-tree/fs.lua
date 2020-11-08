local a = vim.api
local M = {}

function M.rename(node_name)
  local line = a.nvim_get_current_line()
  vim.cmd(":q!")
  if #line == 0 or line == node_name then return end

  local bufs = a.nvim_list_bufs()

  -- rename node
  -- for each buf that has .*/nodename/?.*, replace nodename with new name

  -- send refresh node or just leave the watcher handle that
end

function M.create(cwd)
  local line = a.nvim_get_current_line()
  vim.cmd(":bd!")

  if #line == 0 then return end

  local utils = require'nvim-tree.utils';

  local joined = utils.path_join(cwd, line)
  if utils.ends_with_sep(line) then
    pcall(vim.fn.mkdir, joined, 'p', '0755')
    return require'nvim-tree.actions'.refresh()
  end

  if utils.has_sep(line) then
    local dirs = utils.remove_last_part(line)
    pcall(vim.fn.mkdir, utils.path_join(cwd, dirs), 'p', '0755')
  end

  vim.fn.system('touch '..joined)
  require'nvim-tree.actions'.refresh()
end

return M
