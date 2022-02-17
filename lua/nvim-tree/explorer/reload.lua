local api = vim.api
local uv = vim.loop

local utils = require'nvim-tree.utils'
local eutils = require'nvim-tree.explorer.utils'
local builders = require'nvim-tree.explorer.node-builders'

local M = {}

local function key_by(nodes, key)
  local v = {}
  for _, node in ipairs(nodes) do
    v[node[key]] = node
  end
  return v
end

local function update_status(nodes_by_path, node_ignored, status)
  return function(node)
    if nodes_by_path[node.absolute_path] then
      if node.nodes then
        node.git_status = builders.get_dir_git_status(node_ignored, status, node.absolute_path)
      else
        node.git_status = builders.get_git_status(node_ignored, status, node.absolute_path)
      end
    end
    return node
  end
end

function M.reload(node, cwd, status)
  local handle = uv.fs_scandir(cwd)
  if type(handle) == 'string' then
    api.nvim_err_writeln(handle)
    return
  end

  if node.group_next then
    node.nodes = {node.group_next}
    node.group_next = nil
  end

  local child_names = {}

  local node_ignored = node.git_status == '!!'
  local nodes_by_path = key_by(node.nodes, "absolute_path")
  while true do
    local name, t = uv.fs_scandir_next(handle)
    if not name then break end

    local abs = utils.path_join({cwd, name})
    t = t or (uv.fs_stat(abs) or {}).type
    if not eutils.should_ignore(abs) and not eutils.should_ignore_git(abs, status.files) then
      child_names[abs] = true
      if not nodes_by_path[abs] then
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

  node.nodes = vim.tbl_map(
    update_status(nodes_by_path, node_ignored, status),
    vim.tbl_filter(
      function(n) return child_names[n.absolute_path] end,
      node.nodes
    ))

  local is_root = node.cwd ~= nil
  if vim.g.nvim_tree_group_empty == 1 and not is_root and #(node.nodes) == 1 then
    local child_node = node.nodes[1]
    if child_node.nodes and uv.fs_access(child_node.absolute_path, 'R') then
      node.group_next = child_node
      local ns = M.reload(child_node, child_node.absolute_path, status)
      node.nodes = ns or {}
      return ns
    end
  end

  utils.merge_sort(node.nodes, eutils.node_comparator)
  return node.nodes
end

return M
