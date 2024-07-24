local utils = require "nvim-tree.utils"
local builders = require "nvim-tree.explorer.node-builders"
local explorer_node = require "nvim-tree.explorer.node"
local git = require "nvim-tree.git"
local sorters = require "nvim-tree.explorer.sorters"
local filters = require "nvim-tree.explorer.filters"
local live_filter = require "nvim-tree.live-filter"
local log = require "nvim-tree.log"
-- local explorer_module = require "nvim-tree.explorer"

local FILTER_REASON = filters.FILTER_REASON
local Watcher = require "nvim-tree.watcher"

local M = {}

---@param handle uv.uv_fs_t
---@param cwd string
---@param node Node
---@param git_status table
---@return integer filtered_count
local function populate_children(handle, cwd, node, git_status)
  local node_ignored = explorer_node.is_git_ignored(node)
  local nodes_by_path = utils.bool_record(node.nodes, "absolute_path")

  local filter_status = filters.prepare(git_status)

  node.hidden_count = vim.tbl_deep_extend("force", node.hidden_count or {}, {
    git = 0,
    buf = 0,
    dotfile = 0,
    custom = 0,
    bookmark = 0,
  })

  while true do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    local is_dir = t == "directory"

    local abs = utils.path_join { cwd, name }
    local profile = log.profile_start("explore populate_children %s", abs)

    ---@type uv.fs_stat.result|nil
    local stat = vim.loop.fs_stat(abs)
    local filter_reason = filters.should_filter_as_reason(abs, stat, filter_status)
    if filter_reason == FILTER_REASON.none and not nodes_by_path[abs] and Watcher.is_fs_event_capable(abs) then
      local child = nil
      if is_dir and vim.loop.fs_access(abs, "R") then
        child = builders.folder(node, abs, name, stat)
      elseif t == "file" then
        child = builders.file(node, abs, name, stat)
      elseif t == "link" then
        local link = builders.link(node, abs, name, stat)
        if link.link_to ~= nil then
          child = link
        end
      end
      if child then
        table.insert(node.nodes, child)
        nodes_by_path[child.absolute_path] = true
        explorer_node.update_git_status(child, node_ignored, git_status)
      end
    else
      for reason, value in pairs(FILTER_REASON) do
        if filter_reason == value then
          node.hidden_count[reason] = node.hidden_count[reason] + 1
        end
      end
    end

    log.profile_end(profile)
  end

  -- explorer_module.reload(node)
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
  local old_num = #node.nodes
  sorters.sort(node.nodes)
  live_filter.apply_filter(node)

  log.profile_end(profile)
  local new_num = #node.nodes
  assert(old_num == new_num, vim.inspect { old_num = old_num, new_num = new_num })
  return node.nodes
end

function M.setup(opts)
  M.config = opts.renderer
end

return M
