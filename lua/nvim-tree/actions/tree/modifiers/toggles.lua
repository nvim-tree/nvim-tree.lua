local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")
local M = {}

---@param explorer Explorer
local function reload(explorer)
  local node = explorer:get_node_at_cursor()
  explorer:reload_explorer()
  if node then
    utils.focus_node_or_parent(node)
  end
end

local function wrap_explorer(fn)
  return function(...)
    local explorer = core.get_explorer()
    if explorer then
      return fn(explorer, ...)
    end
  end
end

---@param explorer Explorer
local function custom(explorer)
  explorer.filters.config.filter_custom = not explorer.filters.config.filter_custom
  reload(explorer)
end

---@param explorer Explorer
local function git_ignored(explorer)
  explorer.filters.config.filter_git_ignored = not explorer.filters.config.filter_git_ignored
  reload(explorer)
end

---@param explorer Explorer
local function git_clean(explorer)
  explorer.filters.config.filter_git_clean = not explorer.filters.config.filter_git_clean
  reload(explorer)
end

---@param explorer Explorer
local function no_buffer(explorer)
  explorer.filters.config.filter_no_buffer = not explorer.filters.config.filter_no_buffer
  reload(explorer)
end

---@param explorer Explorer
local function no_bookmark(explorer)
  explorer.filters.config.filter_no_bookmark = not explorer.filters.config.filter_no_bookmark
  reload(explorer)
end

---@param explorer Explorer
local function dotfiles(explorer)
  explorer.filters.config.filter_dotfiles = not explorer.filters.config.filter_dotfiles
  reload(explorer)
end

---@param explorer Explorer
local function enable(explorer)
  explorer.filters.config.enable = not explorer.filters.config.enable
  reload(explorer)
end

M.custom = wrap_explorer(custom)
M.git_ignored = wrap_explorer(git_ignored)
M.git_clean = wrap_explorer(git_clean)
M.no_buffer = wrap_explorer(no_buffer)
M.no_bookmark = wrap_explorer(no_bookmark)
M.dotfiles = wrap_explorer(dotfiles)
M.enable = wrap_explorer(enable)

return M
