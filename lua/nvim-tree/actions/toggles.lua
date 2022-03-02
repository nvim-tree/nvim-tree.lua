local view = require"nvim-tree.view"
local eutils = require"nvim-tree.explorer.utils"
local renderer = require"nvim-tree.renderer"
local reloaders = require"nvim-tree.actions.reloaders"

local M = {}

function M.ignored()
  eutils.config.filter_ignored = not eutils.config.filter_ignored
  return reloaders.reload_explorer()
end

function M.dotfiles()
  eutils.config.filter_dotfiles = not eutils.config.filter_dotfiles
  return reloaders.reload_explorer()
end

function M.help()
  view.toggle_help()
  return renderer.draw()
end

return M
