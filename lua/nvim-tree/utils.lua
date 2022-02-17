local has_notify, notify = pcall(require, 'notify')

local a = vim.api
local uv = vim.loop

local M = {}

M.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1

function M.path_to_matching_str(path)
  return path:gsub('(%-)', '(%%-)'):gsub('(%.)', '(%%.)'):gsub('(%_)', '(%%_)')
end

function M.warn(msg)
  vim.schedule(function()
    if has_notify then
      notify(msg, vim.log.levels.WARN, { title = "NvimTree" })
    else
      vim.notify("[NvimTree] "..msg, vim.log.levels.WARN)
    end
  end)
end

function M.str_find(haystack, needle)
  return vim.fn.stridx(haystack, needle) ~= -1
end

function M.read_file(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then return '' end
  local stat = uv.fs_fstat(fd)
  if not stat then return '' end
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data or ''
end

local path_separator = package.config:sub(1,1)
function M.path_join(paths)
  return table.concat(vim.tbl_map(M.path_remove_trailing, paths), path_separator)
end

function M.path_split(path)
  return path:gmatch('[^'..path_separator..']+'..path_separator..'?')
end

---Get the basename of the given path.
---@param path string
---@return string
function M.path_basename(path)
  path = M.path_remove_trailing(path)
  local i = path:match("^.*()" .. path_separator)
  if not i then return path end
  return path:sub(i + 1, #path)
end

---Get a path relative to another path.
---@param path string
---@param relative_to string
---@return string
function M.path_relative(path, relative_to)
  local p, _ = path:gsub("^" .. M.path_to_matching_str(M.path_add_trailing(relative_to)), "")
  return p
end

function M.path_add_trailing(path)
  if path:sub(-1) == path_separator then
    return path
  end

  return path..path_separator
end

function M.path_remove_trailing(path)
  local p, _ = path:gsub(path_separator..'$', '')
  return p
end

M.path_separator = path_separator

function M.clear_prompt()
  vim.api.nvim_command('normal! :')
end

function M.get_user_input_char()
  local c = vim.fn.getchar()
  while type(c) ~= "number" do
    c = vim.fn.getchar()
  end
  return vim.fn.nr2char(c)
end

-- get the node from the tree that matches the predicate
-- @param nodes list of node
-- @param fn    function(node): boolean
function M.find_node(_nodes, _fn)
  local function iter(nodes, fn)
    local i = 1
    for _, node in ipairs(nodes) do
      if fn(node) then return node, i end
      if node.open and #node.nodes > 0 then
        local n, idx = iter(node.nodes, fn)
        i = i + idx
        if n then return n, i end
      else
        i = i + 1
      end
    end
    return nil, i
  end
  local node, i = iter(_nodes, _fn)
  i = require'nvim-tree.view'.View.hide_root_folder and i - 1 or i
  return node, i
end

---Create a shallow copy of a portion of a list.
---@param t table
---@param first integer First index, inclusive
---@param last integer Last index, inclusive
---@return table
function M.tbl_slice(t, first, last)
  local slice = {}
  for i = first, last or #t, 1 do
    table.insert(slice, t[i])
  end

  return slice
end

local function merge(t, first, mid, last, comparator)
  local n1 = mid - first + 1
  local n2 = last - mid
  local ls = M.tbl_slice(t, first, mid)
  local rs = M.tbl_slice(t, mid + 1, last)
  local i = 1
  local j = 1
  local k = first

  while (i <= n1 and j <= n2) do
    if comparator(ls[i], rs[j]) then
      t[k] = ls[i]
      i = i + 1
    else
      t[k] = rs[j]
      j = j + 1
    end
    k = k + 1
  end

  while i <= n1 do
    t[k] = ls[i]
    i = i + 1
    k = k + 1
  end

  while j <= n2 do
    t[k] = rs[j]
    j = j + 1
    k = k + 1
  end
end

local function split_merge(t, first, last, comparator)
  if (last - first) < 1 then return end

  local mid = math.floor((first + last) / 2)

  split_merge(t, first, mid, comparator)
  split_merge(t, mid + 1, last, comparator)
  merge(t, first, mid, last, comparator)
end

---Perform a merge sort on a given list.
---@param t any[]
---@param comparator function|nil
function M.merge_sort(t, comparator)
  if not comparator then
    comparator = function (left, right)
      return left < right
    end
  end

  split_merge(t, 1, #t, comparator)
end

---Matching executable files in Windows.
---@param ext string
---@return boolean
local PATHEXT = vim.env.PATHEXT or ''
local wexe = vim.split(PATHEXT:gsub('%.', ''), ';')
local pathexts = {}
for _, v in pairs(wexe) do
  pathexts[v] = true
end

function M.is_windows_exe(ext)
  return pathexts[ext:upper()]
end

function M.rename_loaded_buffers(old_name, new_name)
  for _, buf in pairs(a.nvim_list_bufs()) do
    if a.nvim_buf_is_loaded(buf) then
      if a.nvim_buf_get_name(buf) == old_name then
        a.nvim_buf_set_name(buf, new_name)
        -- to avoid the 'overwrite existing file' error message on write
        vim.api.nvim_buf_call(buf, function() vim.cmd("silent! w!") end)
      end
    end
  end
end

--- @param path string path to file or directory
--- @return boolean
function M.file_exists(path)
  local _, error = vim.loop.fs_stat(path)
  return error == nil
end

--- @param path string
--- @return string
function M.canonical_path(path)
  if M.is_windows and path:match '^%a:' then
    return path:sub(1, 1):upper() .. path:sub(2)
  end
  return path
end

return M
