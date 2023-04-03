local utils = require "nvim-tree.utils"
local builders = require "nvim-tree.explorer.node-builders"
local explorer_node = require "nvim-tree.explorer.node"
local filters = require "nvim-tree.explorer.filters"
local sorters = require "nvim-tree.explorer.sorters"
local live_filter = require "nvim-tree.live-filter"
local git = require "nvim-tree.git"
local log = require "nvim-tree.log"

local NodeIterator = require "nvim-tree.iterators.node-iterator"
local Watcher = require "nvim-tree.watcher"

local M = {}

local function update_status(nodes_by_path, node_ignored, status)
  return function(node)
    if nodes_by_path[node.absolute_path] then
      explorer_node.update_git_status(node, node_ignored, status)
    end
    return node
  end
end

-- TODO always use callback once async/await is available
local function reload_and_get_git_project(path, callback)
  local project_root = git.get_project_root(path)

  if callback then
    git.reload_project(project_root, path, function()
      callback(project_root, git.get_project(project_root) or {})
    end)
  else
    git.reload_project(project_root, path)
    return project_root, git.get_project(project_root) or {}
  end
end

local function update_parent_statuses(node, project, root)
  while project and node and node.absolute_path ~= root do
    explorer_node.update_git_status(node, false, project)
    node = node.parent
  end
end

function M.reload(node, git_status, unloaded_bufnr)
  local cwd = node.link_to or node.absolute_path
  local handle = vim.loop.fs_scandir(cwd)
  if not handle then
    return
  end

  local profile = log.profile_start("reload %s", node.absolute_path)

  local filter_status = filters.prepare(git_status, unloaded_bufnr)

  if node.group_next then
    node.nodes = { node.group_next }
    node.group_next = nil
  end

  local child_names = {}

  local node_ignored = explorer_node.is_git_ignored(node)
  local nodes_by_path = utils.key_by(node.nodes, "absolute_path")
  while true do
    local name, t = vim.loop.fs_scandir_next(handle, cwd)
    if not name then
      break
    end

    local stat
    local function fs_stat_cached(path)
      if stat ~= nil then
        return stat
      end

      stat = vim.loop.fs_stat(path)
      return stat
    end

    local abs = utils.path_join { cwd, name }
    t = t or (fs_stat_cached(abs) or {}).type
    if not filters.should_filter(abs, filter_status) then
      child_names[abs] = true

      -- Recreate node if type changes.
      if nodes_by_path[abs] then
        local n = nodes_by_path[abs]

        if n.type ~= t then
          utils.array_remove(node.nodes, n)
          explorer_node.node_destroy(n)
          nodes_by_path[abs] = nil
        end
      end

      if not nodes_by_path[abs] then
        if t == "directory" and vim.loop.fs_access(abs, "R") and Watcher.is_fs_event_capable(abs) then
          local folder = builders.folder(node, abs, name)
          nodes_by_path[abs] = folder
          table.insert(node.nodes, folder)
        elseif t == "file" then
          local file = builders.file(node, abs, name)
          nodes_by_path[abs] = file
          table.insert(node.nodes, file)
        elseif t == "link" then
          local link = builders.link(node, abs, name)
          if link.link_to ~= nil then
            nodes_by_path[abs] = link
            table.insert(node.nodes, link)
          end
        end
      else
        local n = nodes_by_path[abs]
        if n then
          n.executable = builders.is_executable(abs)
          n.fs_stat = fs_stat_cached(abs)
        end
      end
    end
  end

  node.nodes = vim.tbl_map(
    update_status(nodes_by_path, node_ignored, git_status),
    vim.tbl_filter(function(n)
      if child_names[n.absolute_path] then
        return child_names[n.absolute_path]
      else
        explorer_node.node_destroy(n)
        return nil
      end
    end, node.nodes)
  )

  local is_root = not node.parent
  local child_folder_only = explorer_node.has_one_child_folder(node) and node.nodes[1]
  if M.config.group_empty and not is_root and child_folder_only then
    node.group_next = child_folder_only
    local ns = M.reload(child_folder_only, git_status)
    node.nodes = ns or {}
    log.profile_end(profile)
    return ns
  end

  sorters.merge_sort(node.nodes, sorters.node_comparator)
  live_filter.apply_filter(node)
  log.profile_end(profile)
  return node.nodes
end

---Refresh contents and git status for a single node
---@param node table
function M.refresh_node(node, callback)
  if type(node) ~= "table" then
    if callback then
      callback()
    end
    return
  end

  local parent_node = utils.get_parent_of_group(node)

  if callback then
    reload_and_get_git_project(node.absolute_path, function(project_root, project)
      require("nvim-tree.explorer.reload").reload(parent_node, project)

      update_parent_statuses(parent_node, project, project_root)

      callback()
    end)
  else
    -- TODO use callback once async/await is available
    local project_root, project = reload_and_get_git_project(node.absolute_path)

    require("nvim-tree.explorer.reload").reload(parent_node, project)

    update_parent_statuses(parent_node, project, project_root)
  end
end

---Refresh contents and git status for all nodes to a path: actual directory and links
---@param path string absolute path
function M.refresh_nodes_for_path(path)
  local explorer = require("nvim-tree.core").get_explorer()
  if not explorer then
    return
  end

  local profile = log.profile_start("refresh_nodes_for_path %s", path)

  -- avoids cycles
  local absolute_paths_refreshed = {}

  NodeIterator.builder({ explorer })
    :hidden()
    :recursor(function(node)
      if node.group_next then
        return { node.group_next }
      end
      if node.nodes then
        return node.nodes
      end
    end)
    :applier(function(node)
      local abs_contains = node.absolute_path and path:find(node.absolute_path, 1, true) == 1
      local link_contains = node.link_to and path:find(node.link_to, 1, true) == 1
      if abs_contains or link_contains then
        if not absolute_paths_refreshed[node.absolute_path] then
          absolute_paths_refreshed[node.absolute_path] = true
          M.refresh_node(node)
        end
      end
    end)
    :iterate()

  log.profile_end(profile)
end

function M.setup(opts)
  M.config = opts.renderer
end

return M
