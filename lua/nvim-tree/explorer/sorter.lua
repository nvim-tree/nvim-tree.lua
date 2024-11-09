local Class = require("nvim-tree.classic")
local DirectoryNode = require("nvim-tree.node.directory")

---@alias SorterType "name" | "case_sensitive" | "modification_time" | "extension" | "suffix" | "filetype"
---@alias SorterComparator fun(a: Node, b: Node, cfg: SorterCfg): boolean

---@type table<SorterType, SorterComparator>
local C = {}

---@class (exact) SorterCfg
---@field sorter SorterType|fun(nodes: Node[])
---@field folders_first boolean
---@field files_first boolean

---@class (exact) Sorter: Class
---@field private cfg SorterCfg
local Sorter = Class:extend()

---@class Sorter
---@overload fun(args: SorterArgs): Sorter

---@class (exact) SorterArgs
---@field explorer Explorer

---@protected
---@param args SorterArgs
function Sorter:new(args)
  self.cfg = {
    sorter = args.explorer.opts.sort.sorter,
    folders_first = args.explorer.opts.sort.folders_first,
    files_first = args.explorer.opts.sort.files_first,
  }
end

---Predefined comparator
---@param type SorterType
---@return fun(a: Node, b: Node): boolean
function Sorter:get_comparator(type)
  return function(a, b)
    return (C[type] or C.name)(a, b, self.cfg)
  end
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
---@param cfg SorterCfg
---@return boolean|nil
local function folders_or_files_first(a, b, cfg)
  if not (cfg.folders_first or cfg.files_first) then
    return
  end

  if not a:is(DirectoryNode) and b:is(DirectoryNode) then
    -- file <> folder
    return cfg.files_first
  elseif a:is(DirectoryNode) and not b:is(DirectoryNode) then
    -- folder <> file
    return not cfg.files_first
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

  split_merge(t, first,   mid,  comparator)
  split_merge(t, mid + 1, last, comparator)
  merge(t, first, mid, last, comparator)
end

---Perform a merge sort using sorter option.
---@param t Node[]
function Sorter:sort(t)
  if type(self.cfg.sorter) == "function" then
    local t_user = {}
    local origin_index = {}

    for _, n in ipairs(t) do
      table.insert(t_user, {
        absolute_path = n.absolute_path,
        executable    = n.executable,
        extension     = n.extension,
        filetype      = vim.filetype.match({ filename = n.name }),
        link_to       = n.link_to,
        name          = n.name,
        type          = n.type,
      })
      table.insert(origin_index, n)
    end

    local predefined = self.cfg.sorter(t_user)
    if predefined then
      split_merge(t, 1, #t, self:get_comparator(predefined))
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
  elseif type(self.cfg.sorter) == "string" then
    local sorter = self.cfg.sorter --[[@as string]]
    split_merge(t, 1, #t, self:get_comparator(sorter))
  end
end

---@param a Node
---@param b Node
---@param ignorecase boolean|nil
---@param cfg SorterCfg
---@return boolean
local function node_comparator_name_ignorecase_or_not(a, b, ignorecase, cfg)
  if not (a and b) then
    return true
  end

  local early_return = folders_or_files_first(a, b, cfg)
  if early_return ~= nil then
    return early_return
  end

  if ignorecase then
    return a.name:lower() <= b.name:lower()
  else
    return a.name <= b.name
  end
end

---@type SorterComparator
function C.case_sensitive(a, b, cfg)
  return node_comparator_name_ignorecase_or_not(a, b, false, cfg)
end

---@type SorterComparator
function C.name(a, b, cfg)
  return node_comparator_name_ignorecase_or_not(a, b, true, cfg)
end

---@type SorterComparator
function C.modification_time(a, b, cfg)
  if not (a and b) then
    return true
  end

  local early_return = folders_or_files_first(a, b, cfg)
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

---@type SorterComparator
function C.suffix(a, b, cfg)
  if not (a and b) then
    return true
  end

  -- directories go first
  local early_return = folders_or_files_first(a, b, cfg)
  if early_return ~= nil then
    return early_return
  elseif a.nodes and b.nodes then
    return C.name(a, b, cfg)
  end

  -- dotfiles go second
  if a.name:sub(1, 1) == "." and b.name:sub(1, 1) ~= "." then
    return true
  elseif a.name:sub(1, 1) ~= "." and b.name:sub(1, 1) == "." then
    return false
  elseif a.name:sub(1, 1) == "." and b.name:sub(1, 1) == "." then
    return C.name(a, b, cfg)
  end

  -- unsuffixed go third
  local a_suffix_ndx = a.name:find("%.%w+$")
  local b_suffix_ndx = b.name:find("%.%w+$")

  if not a_suffix_ndx and b_suffix_ndx then
    return true
  elseif a_suffix_ndx and not b_suffix_ndx then
    return false
  elseif not (a_suffix_ndx and b_suffix_ndx) then
    return C.name(a, b, cfg)
  end

  -- finally, compare by suffixes
  local a_suffix = a.name:sub(a_suffix_ndx)
  local b_suffix = b.name:sub(b_suffix_ndx)

  if a_suffix and not b_suffix then
    return true
  elseif not a_suffix and b_suffix then
    return false
  elseif a_suffix:lower() == b_suffix:lower() then
    return C.name(a, b, cfg)
  end

  return a_suffix:lower() < b_suffix:lower()
end

---@type SorterComparator
function C.extension(a, b, cfg)
  if not (a and b) then
    return true
  end

  local early_return = folders_or_files_first(a, b, cfg)
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
    return C.name(a, b, cfg)
  end

  return a_ext < b_ext
end

---@type SorterComparator
function C.filetype(a, b, cfg)
  local a_ft = vim.filetype.match({ filename = a.name })
  local b_ft = vim.filetype.match({ filename = b.name })

  -- directories first
  local early_return = folders_or_files_first(a, b, cfg)
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
    return C.name(a, b, cfg)
  end

  return a_ft < b_ft
end

return Sorter
