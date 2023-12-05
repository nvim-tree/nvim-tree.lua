local utils = require "nvim-tree.utils"
local builders = require "nvim-tree.explorer.node-builders"
local explorer_node = require "nvim-tree.explorer.node"
local git = require "nvim-tree.git"
local sorters = require "nvim-tree.explorer.sorters"
local filters = require "nvim-tree.explorer.filters"
local live_filter = require "nvim-tree.live-filter"
local log = require "nvim-tree.log"

local Watcher = require "nvim-tree.watcher"

local M = {}

---@param type_ string|nil
---@param cwd string
---@return any
local function get_type_from(type_, cwd)
  return type_ or (vim.loop.fs_stat(cwd) or {}).type
end

---@param handle uv.uv_fs_t
---@param cwd string
---@param node Node
---@param git_status table
local function populate_children(handle, cwd, node, git_status)
  local node_ignored = explorer_node.is_git_ignored(node)
  local nodes_by_path = utils.bool_record(node.nodes, "absolute_path")
  local filter_status = filters.prepare(git_status)
  while true do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local abs = utils.path_join { cwd, name }

    local profile = log.profile_start("explore populate_children %s", abs)

    t = get_type_from(t, abs)
    if not filters.should_filter(abs, filter_status) and not nodes_by_path[abs] and Watcher.is_fs_event_capable(abs) then
      local child = nil
      if t == "directory" and vim.loop.fs_access(abs, "R") then
        child = builders.folder(node, abs, name)
      elseif t == "file" then
        child = builders.file(node, abs, name)
      elseif t == "link" then
        local link = builders.link(node, abs, name)
        if link.link_to ~= nil then
          child = link
        end
      end
      if child then
        table.insert(node.nodes, child)
        nodes_by_path[child.absolute_path] = true
        explorer_node.update_git_status(child, node_ignored, git_status)
      end
    end

    log.profile_end(profile)
  end
end

---@param node Node
---@param status table
---@return Node[]|nil
function M.explore(node, status)
  local cwd = node.link_to or node.absolute_path
  local handle = vim.loop.fs_scandir(cwd)
  if not handle then
    return
  end

  local profile = log.profile_start("explore init %s", node.absolute_path)

  populate_children(handle, cwd, node, status)

  local is_root = not node.parent
  local child_folder_only = explorer_node.has_one_child_folder(node) and node.nodes[1]
  if M.config.group_empty and not is_root and child_folder_only then
    local child_cwd = child_folder_only.link_to or child_folder_only.absolute_path
    local child_status = git.load_project_status(child_cwd)
    node.group_next = child_folder_only
    local ns = M.explore(child_folder_only, child_status)
    node.nodes = ns or {}

    log.profile_end(profile)
    return ns
  end

  sorters.sort(node.nodes)
  live_filter.apply_filter(node)

  log.profile_end(profile)
  return node.nodes
end

function M.setup(opts)
  M.config = opts.renderer
end

return M
