local M = {}

local C = {}

--- Predefined comparator, defaulting to name
--- @param sort_by string as per options
--- @return function
local function get_comparator(sort_by)
  return C[sort_by] or C.name
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

local function split_merge(t, first, last, comparator)
  if (last - first) < 1 then
    return
  end

  local mid = math.floor((first + last) / 2)

  split_merge(t, first, mid, comparator)
  split_merge(t, mid + 1, last, comparator)
  merge(t, first, mid, last, comparator)
end

---Perform a merge sort using sort_by option.
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
    split_merge(t, 1, #t, get_comparator(M.config.sort_by))
  end
end

local function node_comparator_name_ignorecase_or_not(a, b, ignorecase)
  if not (a and b) then
    return true
  end
  if a.nodes and not b.nodes then
    return true
  elseif not a.nodes and b.nodes then
    return false
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
  if a.nodes and not b.nodes then
    return true
  elseif not a.nodes and b.nodes then
    return false
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

function C.extension(a, b)
  if not (a and b) then
    return true
  end

  if a.nodes and not b.nodes then
    return true
  elseif not a.nodes and b.nodes then
    return false
  end

  if not (a.extension and b.extension) then
    return true
  end

  if a.extension and not b.extension then
    return true
  elseif not a.extension and b.extension then
    return false
  end

  return a.extension:lower() <= b.extension:lower()
end

function M.setup(opts)
  M.config = {}
  M.config.sort_by = opts.sort_by

  if type(opts.sort_by) == "function" then
    C.user = opts.sort_by
  end
end

return M
