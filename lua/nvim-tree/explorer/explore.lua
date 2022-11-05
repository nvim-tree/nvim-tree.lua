local utils = require "nvim-tree.utils"
local builders = require "nvim-tree.explorer.node-builders"
local common = require "nvim-tree.explorer.common"
local sorters = require "nvim-tree.explorer.sorters"
local filters = require "nvim-tree.explorer.filters"
local live_filter = require "nvim-tree.live-filter"
local notify = require "nvim-tree.notify"

local M = {}

local function get_type_from(type_, cwd)
  return type_ or (vim.loop.fs_stat(cwd) or {}).type
end

local function populate_children(handle, cwd, node, status)
  local node_ignored = node.git_status == "!!"
  local nodes_by_path = utils.bool_record(node.nodes, "absolute_path")
  while true do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local abs = utils.path_join { cwd, name }
    t = get_type_from(t, abs)
    if
      not filters.should_ignore(abs)
      and not filters.should_ignore_git(abs, status.files)
      and not nodes_by_path[abs]
    then
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
        common.update_git_status(child, node_ignored, status)
      end
    end
  end
end

local function get_dir_handle(cwd)
  local handle = vim.loop.fs_scandir(cwd)
  if type(handle) == "string" then
    notify.error(handle)
    return
  end
  return handle
end

function M.explore(node, status)
  local cwd = node.link_to or node.absolute_path
  local handle = get_dir_handle(cwd)
  if not handle then
    return
  end

  populate_children(handle, cwd, node, status)

  local is_root = not node.parent
  local child_folder_only = common.has_one_child_folder(node) and node.nodes[1]
  if M.config.group_empty and not is_root and child_folder_only then
    node.group_next = child_folder_only
    local ns = M.explore(child_folder_only, status)
    node.nodes = ns or {}
    return ns
  end

  sorters.merge_sort(node.nodes, sorters.node_comparator)
  live_filter.apply_filter(node)
  return node.nodes
end

function M.setup(opts)
  M.config = opts.renderer
end

return M
