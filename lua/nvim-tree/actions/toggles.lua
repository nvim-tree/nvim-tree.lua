local view = require "nvim-tree.view"
local filters = require "nvim-tree.explorer.filters"
local renderer = require "nvim-tree.renderer"
local reloaders = require "nvim-tree.actions.reloaders"
local diagnostics = require "nvim-tree.diagnostics"

local M = {}

function M.custom()
  filters.config.filter_custom = not filters.config.filter_custom
  return reloaders.reload_explorer()
end

function M.git_ignored()
  filters.config.filter_git_ignored = not filters.config.filter_git_ignored
  return reloaders.reload_explorer()
end

function M.dotfiles()
  filters.config.filter_dotfiles = not filters.config.filter_dotfiles
  return reloaders.reload_explorer()
end

function M.help()
  view.toggle_help()
  renderer.draw()
  if view.is_help_ui() then
    diagnostics.clear()
  else
    diagnostics.update()
  end
end

return M
