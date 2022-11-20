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

  for _, ignore_dir in ipairs(M.ignore_dirs) do
    if vim.fn.match(path, ignore_dir) ~= -1 then
      return true
    end
  end

  return false
end

function M.refresh_node(node)
  if type(node) ~= "table" then
    return
  end

  if node.link_to then
    log.line("watcher", "node event executing refresh '%s' -> '%s'", node.link_to, node.absolute_path)
  else
    log.line("watcher", "node event executing refresh '%s'", node.absolute_path)
  end

  local parent_node = utils.get_parent_of_group(node)

  local project_root, project = reload_and_get_git_project(node.absolute_path)

  require("nvim-tree.explorer.reload").reload(parent_node, project)

  update_parent_statuses(parent_node, project, project_root)

  require("nvim-tree.renderer").draw()
end

function M.create_watcher(node)
  if not M.enabled or type(node) ~= "table" then
    return nil
  end

  local path
  if node.type == "link" then
    path = node.link_to
  else
    path = node.absolute_path
  end

  if is_git(path) or is_folder_ignored(path) then
    return nil
  end

  local function callback(watcher)
    log.line("watcher", "node event scheduled refresh %s", watcher.context)
    utils.debounce(watcher.context, M.debounce_delay, function()
      M.refresh_node(node)
    end)
  end

  M.uid = M.uid + 1
  return Watcher:new(path, nil, callback, {
    context = "explorer:watch:" .. path .. ":" .. M.uid,
    node = node,
  })
end

function M.setup(opts)
  M.enabled = opts.filesystem_watchers.enable
  M.debounce_delay = opts.filesystem_watchers.debounce_delay
  M.ignore_dirs = opts.filesystem_watchers.ignore_dirs
  M.uid = 0
end

return M
