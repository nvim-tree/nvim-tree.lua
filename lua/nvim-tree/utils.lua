local M = {}
local uv = vim.loop
local api = vim.api

function M.path_to_matching_str(path)
  return path:gsub('(%-)', '(%%-)'):gsub('(%.)', '(%%.)'):gsub('(%_)', '(%%_)')
end

function M.echo_warning(msg)
  api.nvim_command('echohl WarningMsg')
  api.nvim_command("echom '[NvimTree] "..msg:gsub("'", "''").."'")
  api.nvim_command('echohl None')
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
  return table.concat(paths, path_separator)
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
function M.find_node(nodes, fn)
  local i = 1
  for _, node in ipairs(nodes) do
    if fn(node) then return node, i end
    if node.open and #node.entries > 0 then
      local n, idx = M.find_node(node.entries, fn)
      i = i + idx
      if n then return n, i end
    else
      i = i + 1
    end
  end
  return nil, i
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
    comparator = function (a, b)
      return a < b
    end
  end

  split_merge(t, 1, #t, comparator)
end

local tracked_functions = {}


---Call fn, but not more than once every x milliseconds.
---@param id string Identifier for the debounce group, such as the function name.
---@param fn function Function to be executed.
---@param frequency_in_ms number Miniumum amount of time between invocations of fn.
---@param callback function Called with the result of executing fn as: callback(success, result)
M.debounce = function(id, fn, frequency_in_ms, callback)
    local fn_data = tracked_functions[id]
    if fn_data == nil then
        -- first call for this id
        fn_data = {
            id = id,
            fn = nil,
            frequency_in_ms = frequency_in_ms,
            postponed_callback = nil,
            in_debounce_period = true,
        }
        tracked_functions[id] = fn_data
    else
        if fn_data.in_debounce_period then
            -- This id was called recently and can't be executed again yet.
            -- Just keep track of the details for this request so it
            -- can be executed at the end of the debounce period.
            -- Last one in wins.
            fn_data.fn = fn
            fn_data.frequency_in_ms = frequency_in_ms
            fn_data.postponed_callback = callback
            return
        end
    end

    -- Run the requested function normally.
    -- Use a pcall to ensure the debounce period is still respected even if
    -- this call throws an error.
    fn_data.in_debounce_period = true
    local success, result = pcall(fn)

    if not success then
      print("Error calling nvim-tree.lib.refresh_tree():", result)
    end

    -- Now schedule the next earliest execution.
    -- If there are no calls to run the same function between now
    -- and when this deferred executes, nothing will happen.
    -- If there are several calls, only the last one in will run.
    vim.defer_fn(function ()
        local current_data = tracked_functions[id]
        local _callback = current_data.postponed_callback
        local _fn = current_data.fn
        current_data.postponed_callback = nil
        current_data.fn = nil
        current_data.in_debounce_period = false
        if _fn ~= nil then
            M.debounce(id, _fn, current_data.frequency_in_ms, _callback)
        end
    end, frequency_in_ms)

    -- The callback function is outside the scope of the debounce period
    if type(callback) == "function" then
        callback(success, result)
    end
end

return M
