local api = vim.api
local luv = vim.loop

local utils = require'nvim-tree.utils'
local eutils = require'nvim-tree.explorer.utils'
local builders = require'nvim-tree.explorer.node-builders'

local M = {}

function M.reload(node, cwd, status)
  local handle = luv.fs_scandir(cwd)
  if type(handle) == 'string' then
    api.nvim_err_writeln(handle)
    return
  end

  local named_nodes = {}
  local cached_nodes = {}
  local nodes_idx = {}
  for i, child in ipairs(node.nodes) do
    child.git_status = (node and node.git_status == '!!' and '!!')
      or (status.files and status.files[child.absolute_path])
      or (status.dirs and status.dirs[child.absolute_path])
    cached_nodes[i] = child.name
    nodes_idx[child.name] = i
    named_nodes[child.name] = child
  end

  local dirs = {}
  local links = {}
  local files = {}
  local new_nodes = {}
  local num_new_nodes = 0

  while true do
    local name, t = luv.fs_scandir_next(handle)
    if not name then break end
    num_new_nodes = num_new_nodes + 1

    local abs = utils.path_join({cwd, name})
    if not eutils.should_ignore(abs) and not eutils.should_ignore_git(abs, status.files) then
      if not t then
        local stat = luv.fs_stat(abs)
        t = stat and stat.type
      end

      if t == 'directory' then
        table.insert(dirs, name)
        new_nodes[name] = true
      elseif t == 'file' then
        table.insert(files, name)
        new_nodes[name] = true
      elseif t == 'link' then
        table.insert(links, name)
        new_nodes[name] = true
      end
    end
  end

  -- Handle grouped dirs
  local child_node = node.group_next
  if child_node then
    child_node.open = true
    if num_new_nodes ~= 1 or not new_nodes[child_node.name] then
      -- dir is no longer only containing a group dir, or group dir has been removed
      -- either way: sever the group link on current dir
      node.nodes = node.group_next
      node.group_next = nil
      named_nodes[child_node.name] = child_node
    else
      node.group_next = child_node
      local ns = M.reload(child_node, child_node.absolute_path, status)
      node.nodes = ns or {}
      return ns
    end
  end

  local idx = 1
  for _, name in ipairs(cached_nodes) do
    local named_node = named_nodes[name]
    if named_node and named_node.link_to then
      -- If the link has been modified: remove it in case the link target has changed.
      local stat = luv.fs_stat(node.absolute_path)
      if stat and named_node.last_modified ~= stat.mtime.sec then
        new_nodes[name] = nil
        named_nodes[name] = nil
      end
    end

    if not new_nodes[name] then
      table.remove(node.nodes, idx)
    else
      idx = idx + 1
    end
  end

  local all = {
    { nodes = dirs, fn = builders.folder, check = function(_, abs) return luv.fs_access(abs, 'R') end },
    { nodes = links, fn = builders.link, check = function(name) return name ~= nil end },
    { nodes = files, fn = builders.file, check = function() return true end }
  }

  local prev = nil
  local change_prev
  local new_nodes_added = false
  local parent_ignored = node.git_status == '!!'
  for _, e in ipairs(all) do
    for _, name in ipairs(e.nodes) do
      change_prev = true
      if not named_nodes[name] then
        local abs = utils.path_join({cwd, name})
        local n = e.fn(abs, name, status, parent_ignored)
        if e.check(n.link_to, n.absolute_path) then
          new_nodes_added = true
          idx = 1
          if prev then
            idx = nodes_idx[prev] + 1
          end
          table.insert(node.nodes, idx, n)
          nodes_idx[name] = idx
          cached_nodes[idx] = name
        else
          change_prev = false
        end
      end
      if change_prev and not (child_node and child_node.name == name) then
        prev = name
      end
    end
  end

  if child_node then
    table.insert(node.nodes, 1, child_node)
  end

  if new_nodes_added then
    utils.merge_sort(node.nodes, eutils.node_comparator)
  end

  return node.nodes
end

return M
