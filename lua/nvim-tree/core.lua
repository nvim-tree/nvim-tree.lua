local events = require("nvim-tree.events")
local notify = require("nvim-tree.notify")
local view = require("nvim-tree.view")
local log = require("nvim-tree.log")
local git = require("nvim-tree.git")
local watcher = require("nvim-tree.watcher")

local M = {}

---@type Explorer|nil
local TreeExplorer = nil
local first_init_done = false

---@param foldername string
function M.init(foldername)
  local profile = log.profile_start("core init %s", foldername)

  if TreeExplorer then
    TreeExplorer:destroy()
  end

  local err, path

  if foldername then
    path, err = vim.uv.fs_realpath(foldername)
  else
    path, err = vim.uv.cwd()
  end
  if path then
    TreeExplorer = require("nvim-tree.explorer")({ path = path })
  else
    notify.error(err)
    TreeExplorer = nil
  end

  if not first_init_done then
    events._dispatch_ready()
    first_init_done = true
  end
  log.profile_end(profile)
end

---@return Explorer|nil
function M.get_explorer()
  return TreeExplorer
end

function M.reset_explorer()
  TreeExplorer = nil
end

---@return string|nil
function M.get_cwd()
  return TreeExplorer and TreeExplorer.absolute_path
end

---@return integer
function M.get_nodes_starting_line()
  local offset = 1
  if view.is_root_folder_visible(M.get_cwd()) then
    offset = offset + 1
  end
  if TreeExplorer and TreeExplorer.live_filter.filter then
    return offset + 1
  end
  return offset
end

function M.purge_all_state()
  view.close_all_tabs()
  view.abandon_all_windows()
  if TreeExplorer then
    git.purge_state()
    TreeExplorer:destroy()
    M.reset_explorer()
  end
  -- purge orphaned that were not destroyed by their nodes
  watcher.purge_watchers()
end

return M
