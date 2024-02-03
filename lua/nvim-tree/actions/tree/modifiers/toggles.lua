local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local filters = require "nvim-tree.explorer.filters"
local reloaders = require "nvim-tree.actions.reloaders"

local M = {}

local function reload()
  local node = lib.get_node_at_cursor()
  reloaders.reload_explorer()
  utils.focus_node_or_parent(node)
end

function M.custom()
  filters.config.filter_custom = not filters.config.filter_custom
  reload()
end

function M.git_ignored()
  filters.config.filter_git_ignored = not filters.config.filter_git_ignored
  reload()
end

function M.git_clean()
  filters.config.filter_git_clean = not filters.config.filter_git_clean
  reload()
end

function M.no_buffer()
  filters.config.filter_no_buffer = not filters.config.filter_no_buffer
  reload()
end

function M.no_bookmark()
  filters.config.filter_no_bookmark = not filters.config.filter_no_bookmark
  reload()
end

function M.dotfiles()
  filters.config.filter_dotfiles = not filters.config.filter_dotfiles
  reload()
end

return M
