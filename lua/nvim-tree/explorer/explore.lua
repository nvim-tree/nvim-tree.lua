local api = vim.api
local uv = vim.loop

local utils = require'nvim-tree.utils'
local eutils = require'nvim-tree.explorer.utils'
local builders = require'nvim-tree.explorer.node-builders'

local M = {}

function M.explore(node, cwd, status)
  local handle = uv.fs_scandir(cwd)
  if type(handle) == 'string' then
    api.nvim_err_writeln(handle)
    return
  end

  local node_ignored = node.git_status == '!!'

  while true do
    local name, t = uv.fs_scandir_next(handle)
    if not name then break end

    local abs = utils.path_join({cwd, name})
    t = t or (uv.fs_stat(abs) or {}).type
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

  if vim.g.nvim_tree_group_empty == 1 then
    local child_node = node.nodes[1]
    if #(node.nodes) == 1 and child_node.nodes and uv.fs_access(child_node.absolute_path, 'R') then
      node.group_next = child_node
      child_node.git_status = node.git_status
      node.nodes = {}
      M.explore(child_node, child_node.absolute_path, status)
      return
    end
  end

  utils.merge_sort(node.nodes, eutils.node_comparator)
end

return M
