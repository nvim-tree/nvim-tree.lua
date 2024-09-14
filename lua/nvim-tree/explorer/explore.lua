local utils = require "nvim-tree.utils"
local builders = require "nvim-tree.explorer.node-builders"
local explorer_node = require "nvim-tree.explorer.node"
local git = require "nvim-tree.git"
local log = require "nvim-tree.log"

local FILTER_REASON = require("nvim-tree.enum").FILTER_REASON
local Watcher = require "nvim-tree.watcher"

local M = {}

---@param handle uv.uv_fs_t
---@param cwd string
---@param node Node
---@param git_status table
---@param parent Explorer
local function populate_children(handle, cwd, node, git_status, parent)
  local node_ignored = explorer_node.is_git_ignored(node)
  local nodes_by_path = utils.bool_record(node.nodes, "absolute_path")

  local filter_status = parent.filters:prepare(git_status)

  node.hidden_stats = vim.tbl_deep_extend("force", node.hidden_stats or {}, {
    git = 0,
    buf = 0,
    dotfile = 0,
    custom = 0,
    bookmark = 0,
  })

  while true do
    local name, _ = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local abs = utils.path_join { cwd, name }

    if Watcher.is_fs_event_capable(abs) then
      local profile = log.profile_start("explore populate_children %s", abs)

      ---@type uv.fs_stat.result|nil
      local stat = vim.loop.fs_stat(abs)

      -- Type must come from fs_stat and not fs_scandir_next to maintain sshfs compatibility
      local type = stat and stat.type or nil

      local filter_reason = parent.filters:should_filter_as_reason(abs, stat, filter_status)
      if filter_reason == FILTER_REASON.none then
        if not nodes_by_path[abs] then
          local child = nil
          if type == "directory" and vim.loop.fs_access(abs, "R") then
            child = builders.folder(node, abs, name, stat)
          elseif type == "file" then
            child = builders.file(node, abs, name, stat)
          elseif type == "link" then
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
        end
      else
        for reason, value in pairs(FILTER_REASON) do
          if filter_reason == value then
            node.hidden_stats[reason] = node.hidden_stats[reason] + 1
          end
        end
      end

      log.profile_end(profile)
    end
  end
end

---@param node Node
---@param status table
---@param parent Explorer
---@return Node[]|nil
function M.explore(node, status, parent)
  local cwd = node.link_to or node.absolute_path
  local handle = vim.loop.fs_scandir(cwd)
  if not handle then
    return
  end

  local profile = log.profile_start("explore init %s", node.absolute_path)

  populate_children(handle, cwd, node, status, parent)

  local is_root = not node.parent
  local child_folder_only = explorer_node.has_one_child_folder(node) and node.nodes[1]
  if M.config.group_empty and not is_root and child_folder_only then
    local child_cwd = child_folder_only.link_to or child_folder_only.absolute_path
    local child_status = git.load_project_status(child_cwd)
    node.group_next = child_folder_only
    local ns = M.explore(child_folder_only, child_status, parent)
    node.nodes = ns or {}

    log.profile_end(profile)
    return ns
  end

  parent.sorters:sort(node.nodes)
  parent.live_filter:apply_filter(node)

  log.profile_end(profile)
  return node.nodes
end

function M.setup(opts)
  M.config = opts.renderer
end

return M
