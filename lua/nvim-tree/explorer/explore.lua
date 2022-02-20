local api = vim.api
local uv = vim.loop

local utils = require'nvim-tree.utils'
local eutils = require'nvim-tree.explorer.utils'
local builders = require'nvim-tree.explorer.node-builders'

local M = {}

local function get_type_from(type_, cwd)
  return type_ or (uv.fs_stat(cwd) or {}).type
end

local function populate_children(handle, cwd, node, status)
  local node_ignored = node.git_status == '!!'
  while true do
    local name, t = uv.fs_scandir_next(handle)
    if not name then break end

    local abs = utils.path_join({cwd, name})
    t = get_type_from(t, abs)
    if not eutils.should_ignore(abs) and not eutils.should_ignore_git(abs, status.files) then
      if t == 'directory' and uv.fs_access(abs, 'R') then
        table.insert(node.nodes, builders.folder(abs, name, status, node_ignored))
      elseif t == 'file' then
        table.insert(node.nodes, builders.file(abs, name, status, node_ignored))
      elseif t == 'link' then
        local link = builders.link(abs, name, status, node_ignored)
        if link.link_to ~= nil then
          table.insert(node.nodes, link)
        end
      end
    end
  end
end

local function get_dir_handle(cwd)
  local handle = uv.fs_scandir(cwd)
  if type(handle) == 'string' then
    api.nvim_err_writeln(handle)
    return
  end
  return handle
end

function M.explore(node, status)
  local cwd = node.cwd or node.link_to or node.absolute_path
  local handle = get_dir_handle(cwd)
  if not handle then return end

  populate_children(handle, cwd, node, status)

  local is_root = node.cwd ~= nil
  local child_folder_only = eutils.has_one_child_folder(node) and node.nodes[1]
  if vim.g.nvim_tree_group_empty == 1 and not is_root and child_folder_only then
    node.group_next = child_folder_only
    local ns = M.explore(child_folder_only, status)
    node.nodes = ns or {}
    return ns
  end

  utils.merge_sort(node.nodes, eutils.node_comparator)
  return node.nodes
end

return M
