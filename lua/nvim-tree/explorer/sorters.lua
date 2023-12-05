local M = {}

local C = {}

--- Predefined comparator, defaulting to name
---@param sorter string as per options
---@return function
local function get_comparator(sorter)
  return C[sorter] or C.name
end

---Create a shallow copy of a portion of a list.
---@param t table
---@param first integer First index, inclusive
---@param last integer Last index, inclusive
---@return table
local function tbl_slice(t, first, last)
  local slice = {}
  for i = first, last or #t, 1 do
    table.insert(slice, t[i])
  end

  return slice
end

---Evaluate `sort.folders_first` and `sort.files_first`
---@param a Node
---@param b Node
---@return boolean|nil
local function folders_or_files_first(a, b)
  if not (M.config.sort.folders_first or M.config.sort.files_first) then
    return
  end

  if not a.nodes and b.nodes then
    -- file <> folder
    return M.config.sort.files_first
  elseif a.nodes and not b.nodes then
    -- folder <> file
    return not M.config.sort.files_first
  end
end

---@param t table
---@param first number
---@param mid number
---@param last number
---@param comparator fun(a: Node, b: Node): boolean
local function merge(t, first, mid, last, comparator)
  local n1 = mid - first + 1
  local n2 = last - mid
  local ls = tbl_slice(t, first, mid)
  local rs = tbl_slice(t, mid + 1, last)
  local i = 1
  local j = 1
  local k = first

  while i <= n1 and j <= n2 do
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

---@param t table
---@param first number
---@param last number
---@param comparator fun(a: Node, b: Node): boolean
local function split_merge(t, first, last, comparator)
  if (last - first) < 1 then
    return
  end

  local mid = math.floor((first + last) / 2)

  split_merge(t, first, mid, comparator)
  split_merge(t, mid + 1, last, comparator)
  merge(t, first, mid, last, comparator)
end

---Perform a merge sort using sorter option.
---@param t table nodes
function M.sort(t)
  if C.user then
    local t_user = {}
    local origin_index = {}

    for _, n in ipairs(t) do
      table.insert(t_user, {
        absolute_path = n.absolute_path,
        executable = n.executable,
        extension = n.extension,
        filetype = vim.filetype.match { filename = n.name },
        link_to = n.link_to,
        name = n.name,
        type = n.type,
      })
      table.insert(origin_index, n)
    end

    local predefined = C.user(t_user)
    if predefined then
      split_merge(t, 1, #t, get_comparator(predefined))
      return
    end

    -- do merge sort for prevent memory exceed
    local user_index = {}
    for i, v in ipairs(t_user) do
      if type(v.absolute_path) == "string" and user_index[v.absolute_path] == nil then
        user_index[v.absolute_path] = i
      end
    end

    -- if missing value found, then using origin_index
    local mini_comparator = function(a, b)
      local a_index = user_index[a.absolute_path] or origin_index[a.absolute_path]
      local b_index = user_index[b.absolute_path] or origin_index[b.absolute_path]

      if type(a_index) == "number" and type(b_index) == "number" then
        return a_index <= b_index
      end
      return (a_index or 0) <= (b_index or 0)
    end

    split_merge(t, 1, #t, mini_comparator) -- sort by user order
  else
    split_merge(t, 1, #t, get_comparator(M.config.sort.sorter))
  end
end

---@param a Node
---@param b Node
---@param ignorecase boolean|nil
---@return boolean
local function node_comparator_name_ignorecase_or_not(a, b, ignorecase)
  if not (a and b) then
    return true
  end

  local early_return = folders_or_files_first(a, b)
  if early_return ~= nil then
    return early_return
  end

  if ignorecase then
    return a.name:lower() <= b.name:lower()
  else
    return a.name <= b.name
  end
end

function C.case_sensitive(a, b)
  return node_comparator_name_ignorecase_or_not(a, b, false)
end

function C.name(a, b)
  return node_comparator_name_ignorecase_or_not(a, b, true)
end

function C.modification_time(a, b)
  if not (a and b) then
    return true
  end

  local early_return = folders_or_files_first(a, b)
  if early_return ~= nil then
    return early_return
  end

  local last_modified_a = 0
  local last_modified_b = 0

  if a.fs_stat ~= nil then
    last_modified_a = a.fs_stat.mtime.sec
  end

  if b.fs_stat ~= nil then
    last_modified_b = b.fs_stat.mtime.sec
  end

  return last_modified_b <= last_modified_a
end

function C.suffix(a, b)
  if not (a and b) then
    return true
  end

  -- directories go first
  local early_return = folders_or_files_first(a, b)
  if early_return ~= nil then
    return early_return
  elseif a.nodes and b.nodes then
    return C.name(a, b)
  end

  -- dotfiles go second
  if a.name:sub(1, 1) == "." and b.name:sub(1, 1) ~= "." then
    return true
  elseif a.name:sub(1, 1) ~= "." and b.name:sub(1, 1) == "." then
    return false
  elseif a.name:sub(1, 1) == "." and b.name:sub(1, 1) == "." then
    return C.name(a, b)
  end

  -- unsuffixed go third
  local a_suffix_ndx = a.name:find "%.%w+$"
  local b_suffix_ndx = b.name:find "%.%w+$"

  if not a_suffix_ndx and b_suffix_ndx then
    return true
  elseif a_suffix_ndx and not b_suffix_ndx then
    return false
  elseif not (a_suffix_ndx and b_suffix_ndx) then
    return C.name(a, b)
  end

  -- finally, compare by suffixes
  local a_suffix = a.name:sub(a_suffix_ndx)
  local b_suffix = b.name:sub(b_suffix_ndx)

  if a_suffix and not b_suffix then
    return true
  elseif not a_suffix and b_suffix then
    return false
  elseif a_suffix:lower() == b_suffix:lower() then
    return C.name(a, b)
  end

  return a_suffix:lower() < b_suffix:lower()
end

function C.extension(a, b)
  if not (a and b) then
    return true
  end

  local early_return = folders_or_files_first(a, b)
  if early_return ~= nil then
    return early_return
  end

  if a.extension and not b.extension then
    return true
  elseif not a.extension and b.extension then
    return false
  end

  local a_ext = (a.extension or ""):lower()
  local b_ext = (b.extension or ""):lower()
  if a_ext == b_ext then
    return C.name(a, b)
  end

  return a_ext < b_ext
end

function C.filetype(a, b)
  local a_ft = vim.filetype.match { filename = a.name }
  local b_ft = vim.filetype.match { filename = b.name }

  -- directories first
  local early_return = folders_or_files_first(a, b)
  if early_return ~= nil then
    return early_return
  end

  -- one is nil, the other wins
  if a_ft and not b_ft then
    return true
  elseif not a_ft and b_ft then
    return false
  end

  -- same filetype or both nil, sort by name
  if a_ft == b_ft then
    return C.name(a, b)
  end

  return a_ft < b_ft
end

function M.setup(opts)
  M.config = {}
  M.config.sort = opts.sort

  if type(M.config.sort.sorter) == "function" then
    C.user = M.config.sort.sorter
  end
end

return M
