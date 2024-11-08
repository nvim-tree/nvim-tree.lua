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
  explorer.filters.states.custom = not explorer.filters.states.custom
  reload(explorer)
end

---@param explorer Explorer
local function git_ignored(explorer)
  explorer.filters.states.git_ignored = not explorer.filters.states.git_ignored
  reload(explorer)
end

---@param explorer Explorer
local function git_clean(explorer)
  explorer.filters.states.git_clean = not explorer.filters.states.git_clean
  reload(explorer)
end

---@param explorer Explorer
local function no_buffer(explorer)
  explorer.filters.states.no_buffer = not explorer.filters.states.no_buffer
  reload(explorer)
end

---@param explorer Explorer
local function no_bookmark(explorer)
  explorer.filters.states.no_bookmark = not explorer.filters.states.no_bookmark
  reload(explorer)
end

---@param explorer Explorer
local function dotfiles(explorer)
  explorer.filters.states.dotfiles = not explorer.filters.states.dotfiles
  reload(explorer)
end

---@param explorer Explorer
local function enable(explorer)
  explorer.filters.enabled = not explorer.filters.enabled
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
