local api = vim.api
local luv = vim.loop

local M = {
  show_ignored = false,
  show_dotfiles = vim.g.nvim_tree_hide_dotfiles ~= 1,
}

local utils = require'nvim-tree.utils'
local path_to_matching_str = utils.path_to_matching_str

local function dir_new(cwd, name)
  local absolute_path = utils.path_join({cwd, name})
  local stat = luv.fs_stat(absolute_path)
  local handle = luv.fs_scandir(absolute_path)
  local has_children = handle and luv.fs_scandir_next(handle) ~= nil

  --- This is because i have some folders that i dont have permissions to read its metadata, so i have to check that stat returns a valid info
  local last_modified = 0
  if stat ~= nil then
    last_modified = stat.mtime.sec
  end

  return {
    name = name,
    absolute_path = absolute_path,
    -- TODO: last modified could also involve atime and ctime
    last_modified = last_modified,
    match_name = path_to_matching_str(name),
    match_path = path_to_matching_str(absolute_path),
    open = false,
    group_next = nil,   -- If node is grouped, this points to the next child dir/link node
    has_children = has_children,
    entries = {}
  }
end

local function file_new(cwd, name)
  local absolute_path = utils.path_join({cwd, name})
  local is_exec = luv.fs_access(absolute_path, 'X')
  return {
    name = name,
    absolute_path = absolute_path,
    executable = is_exec,
    extension = string.match(name, ".?[^.]+%.(.*)") or "",
    match_name = path_to_matching_str(name),
    match_path = path_to_matching_str(absolute_path),
  }
end

-- TODO-INFO: sometimes fs_realpath returns nil
-- I expect this be a bug in glibc, because it fails to retrieve the path for some
-- links (for instance libr2.so in /usr/lib) and thus even with a C program realpath fails
-- when it has no real reason to. Maybe there is a reason, but errno is definitely wrong.
-- So we need to check for link_to ~= nil when adding new links to the main tree
local function link_new(cwd, name)

  --- I dont know if this is needed, because in my understanding, there isnt hard links in windows, but just to be sure i changed it.
  local absolute_path = utils.path_join({ cwd, name })
  local link_to = luv.fs_realpath(absolute_path)
  local stat = luv.fs_stat(absolute_path)
  local open, entries
  if (link_to ~= nil) and luv.fs_stat(link_to).type == 'directory' then
    open = false
    entries = {}
  end

  local last_modified = 0
  if stat ~= nil then
    last_modified = stat.mtime.sec
  end

  return {
    name = name,
    absolute_path = absolute_path,
    link_to = link_to,
    last_modified = last_modified,
    open = open,
    group_next = nil,   -- If node is grouped, this points to the next child dir/link node
    entries = entries,
    match_name = path_to_matching_str(name),
    match_path = path_to_matching_str(absolute_path),
  }
end

-- Returns true if there is either exactly 1 dir, or exactly 1 symlink dir. Otherwise, false.
-- @param cwd Absolute path to the parent directory
-- @param dirs List of dir names
-- @param files List of file names
-- @param links List of symlink names
local function should_group(cwd, dirs, files, links)
  if #dirs == 1 and #files == 0 and #links == 0 then
    return true
  end

  if #dirs == 0 and #files == 0 and #links == 1 then
    local absolute_path = utils.path_join({ cwd, links[1] })
    local link_to = luv.fs_realpath(absolute_path)
    return (link_to ~= nil) and luv.fs_stat(link_to).type == 'directory'
  end

  return false
end

local function node_comparator(a, b)
  if a.entries and not b.entries then
    return true
  elseif not a.entries and b.entries then
    return false
  end

  return a.name:lower() <= b.name:lower()
end

local function gen_ignore_check(cwd)
  if not cwd then cwd = luv.cwd() end
  local ignore_list = {}

  if vim.g.nvim_tree_ignore and #vim.g.nvim_tree_ignore > 0 then
    for _, entry in pairs(vim.g.nvim_tree_ignore) do
      ignore_list[entry] = true
    end
  end

  ---Check if the given path should be ignored.
  ---@param path string Absolute path
  ---@return boolean
  return function(path)
    local basename = utils.path_basename(path)

    if not M.show_ignored then
      local relpath = utils.path_relative(path, cwd)
      if ignore_list[relpath] == true or ignore_list[basename] == true then
        return true
      end

      local idx = path:match(".+()%.[^.]+$")
      if idx then
        if ignore_list['*'..string.sub(path, idx)] == true then return true end
      end
    end

    if not M.show_dotfiles then
      if basename:sub(1, 1) == '.' then return true end
    end

    return false
  end
end

local should_ignore = gen_ignore_check()

function M.refresh_entries(entries, cwd, parent_node)
  local handle = luv.fs_scandir(cwd)
  if type(handle) == 'string' then
    api.nvim_err_writeln(handle)
    return
  end

  local named_entries = {}
  local cached_entries = {}
  local entries_idx = {}
  for i, node in ipairs(entries) do
    cached_entries[i] = node.name
    entries_idx[node.name] = i
    named_entries[node.name] = node
  end

  local dirs = {}
  local links = {}
  local files = {}
  local new_entries = {}
  local num_new_entries = 0

  while true do
    local name, t = luv.fs_scandir_next(handle)
    if not name then break end
    num_new_entries = num_new_entries + 1

    local abs = utils.path_join({cwd, name})
    if not should_ignore(abs) then
      if not t then
        local stat = luv.fs_stat(abs)
        t = stat and stat.type
      end

      if t == 'directory' then
        table.insert(dirs, name)
        new_entries[name] = true
      elseif t == 'file' then
        table.insert(files, name)
        new_entries[name] = true
      elseif t == 'link' then
        table.insert(links, name)
        new_entries[name] = true
      end
    end
  end

  -- Handle grouped dirs
  local next_node = parent_node.group_next
  if next_node then
    next_node.open = parent_node.open
    if num_new_entries ~= 1 or not new_entries[next_node.name] then
      -- dir is no longer only containing a group dir, or group dir has been removed
      -- either way: sever the group link on current dir
      parent_node.group_next = nil
      named_entries[next_node.name] = next_node
    else
      M.refresh_entries(entries, next_node.absolute_path, next_node)
      return
    end
  end

  local idx = 1
  for _, name in ipairs(cached_entries) do
    local node = named_entries[name]
    if node and node.link_to then
      -- If the link has been modified: remove it in case the link target has changed.
      local stat = luv.fs_stat(node.absolute_path)
      if stat and node.last_modified ~= stat.mtime.sec then
        new_entries[name] = nil
        named_entries[name] = nil
      end
    end

    if not new_entries[name] then
      table.remove(entries, idx)
    else
      idx = idx + 1
    end
  end

  local all = {
    { entries = dirs, fn = dir_new, check = function(_, abs) return luv.fs_access(abs, 'R') end },
    { entries = links, fn = link_new, check = function(name) return name ~= nil end },
    { entries = files, fn = file_new, check = function() return true end }
  }

  local prev = nil
  local change_prev
  local new_nodes_added = false
  for _, e in ipairs(all) do
    for _, name in ipairs(e.entries) do
      change_prev = true
      if not named_entries[name] then
        local n = e.fn(cwd, name)
        if e.check(n.link_to, n.absolute_path) then
          new_nodes_added = true
          idx = 1
          if prev then
            idx = entries_idx[prev] + 1
          end
          table.insert(entries, idx, n)
          entries_idx[name] = idx
          cached_entries[idx] = name
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
    table.insert(entries, 1, next_node)
  end

  if new_nodes_added then
    utils.merge_sort(entries, node_comparator)
  end
end

function M.populate(entries, cwd, parent_node)
  local handle = luv.fs_scandir(cwd)
  if type(handle) == 'string' then
    api.nvim_err_writeln(handle)
    return
  end

  local dirs = {}
  local links = {}
  local files = {}

  while true do
    local name, t = luv.fs_scandir_next(handle)
    if not name then break end

    local abs = utils.path_join({cwd, name})
    if not should_ignore(abs) then
      if not t then
        local stat = luv.fs_stat(abs)
        t = stat and stat.type
      end

      if t == 'directory' then
        table.insert(dirs, name)
      elseif t == 'file' then
        table.insert(files, name)
      elseif t == 'link' then
        table.insert(links, name)
      end
    end
  end

  -- Create Nodes --

  -- Group empty dirs
  if parent_node and vim.g.nvim_tree_group_empty == 1 then
    if should_group(cwd, dirs, files, links) then
      local child_node
      if dirs[1] then child_node = dir_new(cwd, dirs[1]) end
      if links[1] then child_node = link_new(cwd, links[1]) end
      if luv.fs_access(child_node.absolute_path, 'R') then
        parent_node.group_next = child_node
        child_node.git_status = parent_node.git_status
        M.populate(entries, child_node.absolute_path, child_node)
        return
      end
    end
  end

  for _, dirname in ipairs(dirs) do
    local dir = dir_new(cwd, dirname)
    if luv.fs_access(dir.absolute_path, 'R') then
      table.insert(entries, dir)
    end
  end

  for _, linkname in ipairs(links) do
    local link = link_new(cwd, linkname)
    if link.link_to ~= nil then
      table.insert(entries, link)
    end
  end

  for _, filename in ipairs(files) do
    local file = file_new(cwd, filename)
    table.insert(entries, file)
  end

  utils.merge_sort(entries, node_comparator)
end

return M
