local config = require'lib.config'
local git = require'lib.git'
local icon_config = config.get_icon_state()

local api = vim.api
local luv = vim.loop

local M = {}

local function path_to_matching_str(path)
  return path:gsub('(%-)', '(%%-)'):gsub('(%.)', '(%%.)')
end

local function dir_new(cwd, name)
  local absolute_path = cwd..'/'..name
  local stat = luv.fs_stat(absolute_path)
  return {
    name = name,
    absolute_path = absolute_path,
    -- TODO: last modified could also involve atime and ctime
    last_modified = stat.mtime.sec,
    match_name = path_to_matching_str(name),
    match_path = path_to_matching_str(absolute_path),
    open = false,
    entries = {}
  }
end

local function file_new(cwd, name)
  local absolute_path = cwd..'/'..name
  local is_exec = luv.fs_access(absolute_path, 'X')
  return {
    name = name,
    absolute_path = absolute_path,
    executable = is_exec,
    extension = vim.fn.fnamemodify(name, ':e') or "",
    match_name = path_to_matching_str(name),
    match_path = path_to_matching_str(absolute_path),
  }
end

local function link_new(cwd, name)
  local absolute_path = cwd..'/'..name
  local link_to = luv.fs_realpath(absolute_path)
  return {
    name = name,
    absolute_path = absolute_path,
    link_to = link_to,
    match_name = path_to_matching_str(name),
    match_path = path_to_matching_str(absolute_path),
  }
end

local function gen_ignore_check()
  local ignore_list = {}
  if vim.g.lua_tree_ignore and #vim.g.lua_tree_ignore > 0 then
    for _, entry in pairs(vim.g.lua_tree_ignore) do
      ignore_list[entry] = true
    end
  end

  return function(path)
    return ignore_list[path] == true
  end
end

local should_ignore = gen_ignore_check()

function M.refresh_entries(entries, cwd)
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

  while true do
    local name, t = luv.fs_scandir_next(handle)
    if not name then break end
    if should_ignore(name) then goto continue end

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

    ::continue::
  end

  local all = {
    { entries = dirs, fn = dir_new },
    { entries = links, fn = link_new },
    { entries = files, fn = file_new }
  }

  local prev = nil
  for _, e in ipairs(all) do
    for _, name in ipairs(e.entries) do
      if not named_entries[name] then
        local n = e.fn(cwd, name)

        local idx = 1
        if prev then
          idx = entries_idx[prev] + 1
        end
        table.insert(entries, idx, n)
        entries_idx[name] = idx
        cached_entries[idx] = name
      end
      prev = name
    end
  end

  local idx = 1
  for _, name in ipairs(cached_entries) do
    if not new_entries[name] then
      table.remove(entries, idx, idx + 1)
    else
      idx = idx + 1
    end
  end
end

function M.populate(entries, cwd)
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

    if t == 'directory' then
      table.insert(dirs, name)
    elseif t == 'file' then
      table.insert(files, name)
    elseif t == 'link' then
      table.insert(links, name)
    end
  end

  -- Create Nodes --

  for _, dirname in ipairs(dirs) do
    local dir = dir_new(cwd, dirname)
    if not should_ignore(dir.name) and luv.fs_access(dir.absolute_path, 'R') then
      table.insert(entries, dir)
    end
  end

  for _, linkname in ipairs(links) do
    local link = link_new(cwd, linkname)
    if not should_ignore(link.name) then
      table.insert(entries, link)
    end
  end

  for _, filename in ipairs(files) do
    local file = file_new(cwd, filename)
    if not should_ignore(file.name) then
      table.insert(entries, file)
    end
  end

  if not icon_config.show_git_icon then
    return
  end

  git.update_status(entries, cwd)
end

return M
