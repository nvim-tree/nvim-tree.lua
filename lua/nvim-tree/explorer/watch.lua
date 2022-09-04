local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local git = require "nvim-tree.git"
local Watcher = require("nvim-tree.watcher").Watcher

local M = {}

local function reload_and_get_git_project(path)
  local project_root = git.get_project_root(path)
  git.reload_project(project_root, path)
  return project_root, git.get_project(project_root) or {}
end

local function update_parent_statuses(node, project, root)
  while project and node and node.absolute_path ~= root do
    require("nvim-tree.explorer.common").update_git_status(node, false, project)
    node = node.parent
  end
end

local function is_git(path)
  return vim.fn.fnamemodify(path, ":t") == ".git"
end

local IGNORED_PATHS = {
  -- disable watchers on kernel filesystems
  -- which have a lot of unwanted events
  "/sys",
  "/proc",
  "/dev",
}

local function is_folder_ignored(path)
  for _, folder in ipairs(IGNORED_PATHS) do
    if vim.startswith(path, folder) then
      return true
    end
  end
  return false
end

local function refresh_path(path)
  log.line("watcher", "node event executing '%s'", path)
  local n = utils.get_node_from_path(path)
  if not n then
    return
  end

  local node = utils.get_parent_of_group(n)
  local project_root, project = reload_and_get_git_project(path)
  require("nvim-tree.explorer.reload").reload(node, project)
  update_parent_statuses(node, project, project_root)

  require("nvim-tree.renderer").draw()
end

function M.create_watcher(absolute_path)
  if not M.enabled then
    return nil
  end
  if is_git(absolute_path) or is_folder_ignored(absolute_path) then
    return nil
  end

  local function callback(watcher)
    log.line("watcher", "node event scheduled %s", watcher.context)
    utils.debounce(watcher.context, M.debounce_delay, function()
      refresh_path(watcher._path)
    end)
  end

  M.uid = M.uid + 1
  return Watcher:new(absolute_path, callback, {
    context = "explorer:watch:" .. absolute_path .. ":" .. M.uid,
  })
end

function M.setup(opts)
  M.enabled = opts.filesystem_watchers.enable
  M.debounce_delay = opts.filesystem_watchers.debounce_delay
  M.uid = 0
end

return M
