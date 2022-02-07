local M = {}

function M.ignored()
  local config = require"nvim-tree.explorer.utils".config
  config.filter_ignored = not config.filter_ignored
  return require'nvim-tree.actions.reloaders'.reload_explorer()
end

function M.dotfiles()
  local config = require"nvim-tree.explorer.utils".config
  config.filter_dotfiles = not config.filter_dotfiles
  return require'nvim-tree.actions.reloaders'.reload_explorer()
end

return M
