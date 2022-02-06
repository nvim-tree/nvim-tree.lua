local api = vim.api
local luv = vim.loop

local utils = require'nvim-tree.utils'
local eutils = require'nvim-tree.explorer.utils'
local builders = require'nvim-tree.explorer.node-builders'

local M = {}

function M.reload(nodes, cwd, parent_node, status)
  local handle = luv.fs_scandir(cwd)
  if type(handle) == 'string' then
    api.nvim_err_writeln(handle)
    return
  end

  local named_nodes = {}
  local cached_nodes = {}
  local nodes_idx = {}
  for i, node in ipairs(nodes) do
    node.git_status = (parent_node and parent_node.git_status == '!!' and '!!')
      or (status.files and status.files[node.absolute_path])
      or (status.dirs and status.dirs[node.absolute_path])
    cached_nodes[i] = node.name
    nodes_idx[node.name] = i
    named_nodes[node.name] = node
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
  local next_node = parent_node.group_next
  if next_node then
    next_node.open = parent_node.open
    if num_new_nodes ~= 1 or not new_nodes[next_node.name] then
      -- dir is no longer only containing a group dir, or group dir has been removed
      -- either way: sever the group link on current dir
      parent_node.group_next = nil
      named_nodes[next_node.name] = next_node
    else
      M.reload(nodes, next_node.absolute_path, next_node, status)
      return
    end
  end

  local idx = 1
  for _, name in ipairs(cached_nodes) do
    local node = named_nodes[name]
    if node and node.link_to then
      -- If the link has been modified: remove it in case the link target has changed.
      local stat = luv.fs_stat(node.absolute_path)
      if stat and node.last_modified ~= stat.mtime.sec then
        new_nodes[name] = nil
        named_nodes[name] = nil
      end
    end

    if not new_nodes[name] then
      table.remove(nodes, idx)
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
  for _, e in ipairs(all) do
    for _, name in ipairs(e.nodes) do
      change_prev = true
      if not named_nodes[name] then
        local n = e.fn(cwd, name, status)
        if e.check(n.link_to, n.absolute_path) then
          new_nodes_added = true
          idx = 1
          if prev then
            idx = nodes_idx[prev] + 1
          end
          table.insert(nodes, idx, n)
          nodes_idx[name] = idx
          cached_nodes[idx] = name
        else
          change_prev = false
        end
      end
      if change_prev and not (next_node and next_node.name == name) then
        prev = name
      end
    end
  end

  if next_node then
    table.insert(nodes, 1, next_node)
  end

  if new_nodes_added then
    utils.merge_sort(nodes, eutils.node_comparator)
  end
end

return M
