local Iterator = require("nvim-tree.iterators.node-iterator")

local M = {
  debouncers = {},
}

M.is_unix = vim.fn.has("unix") == 1
M.is_macos = vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
M.is_wsl = vim.fn.has("wsl") == 1
-- false for WSL
M.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1

---@param haystack string
---@param needle string
---@return boolean
function M.str_find(haystack, needle)
  return vim.fn.stridx(haystack, needle) ~= -1
end

---@param path string
---@return string|uv.uv_fs_t
function M.read_file(path)
  local fd = vim.loop.fs_open(path, "r", 438)
  if not fd then
    return ""
  end
  local stat = vim.loop.fs_fstat(fd)
  if not stat then
    return ""
  end
  local data = vim.loop.fs_read(fd, stat.size, 0)
  vim.loop.fs_close(fd)
  return data or ""
end

local path_separator = package.config:sub(1, 1)
---@param paths string[]
---@return string
function M.path_join(paths)
  return table.concat(vim.tbl_map(M.path_remove_trailing, paths), path_separator)
end

---@param path string
---@return fun(): string
function M.path_split(path)
  return path:gmatch("[^" .. path_separator .. "]+" .. path_separator .. "?")
end

--- Get the basename of the given path.
---@param path string
---@return string
function M.path_basename(path)
  path = M.path_remove_trailing(path)
  local i = path:match("^.*()" .. path_separator)
  if not i then
    return path
  end
  return path:sub(i + 1, #path)
end

--- Check if there are parentheses before brackets, it causes problems for windows.
--- Refer to issue #2862 and #2961 for more details.
local function has_parentheses_and_brackets(path)
  local _, i_parentheses = path:find("(", 1, true)
  local _, i_brackets = path:find("[", 1, true)
  if i_parentheses and i_brackets then
    return true
  end
  return false
end

--- Path normalizations for windows only
local function win_norm_path(path)
  if path == nil then
    return path
  end
  local norm_path = path
  -- Normalize for issue #2862 and #2961
  if has_parentheses_and_brackets(norm_path) then
    norm_path = norm_path:gsub("/", "\\")
  end
  -- Normalize the drive letter
  norm_path = norm_path:gsub("^%l:", function(drive)
    return drive:upper()
  end)
  return norm_path
end

--- Get a path relative to another path.
---@param path string
---@param relative_to string|nil
---@return string
function M.path_relative(path, relative_to)
  if relative_to == nil then
    return path
  end

  local norm_path = path
  if M.is_windows then
    norm_path = win_norm_path(norm_path)
  end

  local _, r = norm_path:find(M.path_add_trailing(relative_to), 1, true)
  local p = norm_path
  if r then
    -- take the relative path starting after '/'
    -- if somehow given a completely matching path,
    -- returns ""
    p = norm_path:sub(r + 1)
  end
  return p
end

---@param path string
---@return string
function M.path_add_trailing(path)
  if path:sub(-1) == path_separator then
    return path
  end

  return path .. path_separator
end

---@param path string
---@return string
function M.path_remove_trailing(path)
  local p, _ = path:gsub(path_separator .. "$", "")
  return p
end

M.path_separator = path_separator

--- Get the node and index of the node from the tree that matches the predicate.
--- The explored nodes are those displayed on the view.
---@param nodes Node[]
---@param fn fun(node: Node): boolean
---@return table|nil
---@return number
function M.find_node(nodes, fn)
  local node, i = Iterator.builder(nodes)
    :matcher(fn)
    :recursor(function(node)
      return node.group_next and { node.group_next } or (node.open and #node.nodes > 0 and node.nodes)
    end)
    :iterate()

  if node then
    if not node.explorer.view:is_root_folder_visible() then
      i = i - 1
    end
    if node.explorer.live_filter.filter then
      i = i + 1
    end
  end

  return node, i
end

-- Find the line number of a node.
-- Return -1 is node is nil or not found.
---@param node Node?
---@return integer
function M.find_node_line(node)
  if not node then
    return -1
  end

  local first_node_line = require("nvim-tree.core").get_nodes_starting_line()
  local nodes_by_line = M.get_nodes_by_line(require("nvim-tree.core").get_explorer().nodes, first_node_line)
  local iter_start, iter_end = first_node_line, #nodes_by_line

  for line = iter_start, iter_end, 1 do
    if nodes_by_line[line] == node then
      return line
    end
  end

  return -1
end

---@param extmarks vim.api.keyset.get_extmark_item[] as per vim.api.nvim_buf_get_extmarks
---@return number
function M.extmarks_length(extmarks)
  local length = 0
  for _, extmark in ipairs(extmarks) do
    local details = extmark[4]
    if details and details.virt_text then
      for _, text in ipairs(details.virt_text) do
        length = length + vim.fn.strchars(text[1])
      end
    end
  end
  return length
end

-- get the node in the tree state depending on the absolute path of the node
-- (grouped or hidden too)
---@param path string
---@return Node|nil
---@return number|nil
function M.get_node_from_path(path)
  local explorer = require("nvim-tree.core").get_explorer()

  -- tree may not yet be loaded
  if not explorer then
    return
  end

  if explorer.absolute_path == path then
    return explorer
  end

  return Iterator.builder(explorer.nodes)
    :hidden()
    :matcher(function(node)
      return node.absolute_path == path or node.link_to == path
    end)
    :recursor(function(node)
      if node.group_next then
        return { node.group_next }
      end
      if node.nodes then
        return node.nodes
      end
    end)
    :iterate()
end

M.default_format_hidden_count = function(hidden_count, simple)
  local parts = {}
  local total_count = 0
  for reason, count in pairs(hidden_count) do
    total_count = total_count + count
    if count > 0 then
      table.insert(parts, reason .. ": " .. tostring(count))
    end
  end

  local hidden_count_string = table.concat(parts, ", ") -- if empty then is "" (empty string)
  if simple then
    hidden_count_string = ""
  end
  if total_count > 0 then
    return "(" .. tostring(total_count) .. (simple and " hidden" or " total ") .. hidden_count_string .. ")"
  end
  return nil
end

--- Return visible nodes indexed by line
---@param nodes_all Node[]
---@param line_start number
---@return table
function M.get_nodes_by_line(nodes_all, line_start)
  local nodes_by_line = {}
  local line = line_start

  Iterator.builder(nodes_all)
    :applier(function(node)
      if node.group_next then
        return
      end
      nodes_by_line[line] = node
      line = line + 1
    end)
    :recursor(function(node)
      return node.group_next and { node.group_next } or (node.open and #node.nodes > 0 and node.nodes)
    end)
    :iterate()

  return nodes_by_line
end

function M.rename_loaded_buffers(old_path, new_path)
  -- delete new if it exists
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == new_path then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end

  -- rename old to new
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      local exact_match = buf_name == old_path
      local child_match = (buf_name:sub(1, #old_path) == old_path and buf_name:sub(#old_path + 1, #old_path + 1) == path_separator)
      if exact_match or child_match then
        vim.api.nvim_buf_set_name(buf, new_path .. buf_name:sub(#old_path + 1))
        -- to avoid the 'overwrite existing file' error message on write for
        -- normal files
        local buftype
        if vim.fn.has("nvim-0.10") == 1 then
          buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
        else
          buftype = vim.api.nvim_buf_get_option(buf, "buftype") ---@diagnostic disable-line: deprecated
        end

        if buftype == "" then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent! write!")
            vim.cmd("edit")
          end)
        end
      end
    end
  end
end

local is_windows_drive = function(path)
  return (M.is_windows) and (path:match("^%a:\\$") ~= nil)
end

---@param path string path to file or directory
---@return boolean
function M.file_exists(path)
  if not (M.is_windows or M.is_wsl) then
    local _, error = vim.loop.fs_stat(path)
    return error == nil
  end

  -- Windows is case-insensetive, but case-preserving
  -- If a file's name is being changed into itself
  -- with different casing, windows will falsely
  -- report that file is already existing, so a hand-rolled
  -- implementation of checking for existance is needed.
  -- Same holds for WSL, since it can sometimes
  -- access Windows files directly.
  -- For more details see (#3117).

  if is_windows_drive(path) then
    return vim.fn.isdirectory(path) == 1
  end

  local parent = vim.fn.fnamemodify(path, ":h")
  local filename = vim.fn.fnamemodify(path, ":t")

  local handle = vim.loop.fs_scandir(parent)
  if not handle then
    -- File can not exist if its parent directory does not exist
    return false
  end

  while true do
    local name, _ = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    if name == filename then
      return true
    end
  end

  return false
end

---@param path string
---@return string
function M.canonical_path(path)
  if M.is_windows and path:match("^%a:") then
    return path:sub(1, 1):upper() .. path:sub(2)
  end
  return path
end

--- Escapes special characters in string for windows, refer to issue #2862 and #2961 for more details.
local function escape_special_char_for_windows(path)
  if has_parentheses_and_brackets(path) then
    return path:gsub("\\", "/"):gsub("/ ", "\\ ")
  end
  return path:gsub("%(", "\\("):gsub("%)", "\\)")
end

--- Escapes special characters in string if windows else returns unmodified string.
---@param path string
---@return string|nil
function M.escape_special_chars(path)
  if path == nil then
    return path
  end
  return M.is_windows and escape_special_char_for_windows(path) or path
end

--- Create empty sub-tables if not present
---@param tbl table to create empty inside of
---@param path string dot separated string of sub-tables
---@return table deepest sub-table
function M.table_create_missing(tbl, path)
  local t = tbl
  for s in string.gmatch(path, "([^%.]+)%.*") do
    if t[s] == nil then
      t[s] = {}
    end
    t = t[s]
  end

  return t
end

--- Move a value from src to dst if value is nil on dst.
--- Remove value from src
---@param src table to copy from
---@param src_path string dot separated string of sub-tables
---@param src_pos string value pos
---@param dst table to copy to
---@param dst_path string dot separated string of sub-tables, created when missing
---@param dst_pos string value pos
---@param remove boolean
function M.move_missing_val(src, src_path, src_pos, dst, dst_path, dst_pos, remove)
  for pos in string.gmatch(src_path, "([^%.]+)%.*") do
    if src[pos] and type(src[pos]) == "table" then
      src = src[pos]
    else
      return
    end
  end
  local src_val = src[src_pos]
  if src_val == nil then
    return
  end

  dst = M.table_create_missing(dst, dst_path)
  if dst[dst_pos] == nil then
    dst[dst_pos] = src_val
  end

  if remove then
    src[src_pos] = nil
  end
end

local function round(value)
  -- Amount of digits to round to after floating point.
  local digits = 2
  local round_number = 10 ^ digits
  return math.floor((value * round_number) + 0.5) / round_number
end

function M.format_bytes(bytes)
  local units = { "B", "K", "M", "G", "T", "P", "E", "Z", "Y" }
  local i = "i" -- bInary

  bytes = math.max(bytes, 0)
  local pow = math.floor((bytes and math.log(bytes) or 0) / math.log(1024))
  pow = math.min(pow, #units)

  local value = round(bytes / (1024 ^ pow))

  pow = pow + 1

  -- units[pow] == nil when size == 0 B or size >= 1024 YiB
  if units[pow] == nil or pow == 1 then
    if bytes < 1024 then
      return bytes .. " " .. units[1]
    else
      -- Use the biggest adopted multiple of 2 instead of bytes.
      value = round(bytes / (1024 ^ (#units - 1)))
      -- For big numbers decimal part is not useful.
      return string.format("%.0f %s%s%s", value, units[#units], i, units[1])
    end
  else
    return value .. " " .. units[pow] .. i .. units[1]
  end
end

function M.key_by(tbl, key)
  local keyed = {}
  for _, val in ipairs(tbl) do
    if val[key] then
      keyed[val[key]] = val
    end
  end
  return keyed
end

function M.bool_record(tbl, key)
  local keyed = {}
  for _, val in ipairs(tbl) do
    keyed[val[key]] = true
  end
  return keyed
end

local function timer_stop_close(timer)
  if timer:is_active() then
    timer:stop()
  end
  if not timer:is_closing() then
    timer:close()
  end
end

---Execute callback timeout ms after the latest invocation with context.
---Waiting invocations for that context will be discarded.
---Invocation will be rescheduled while a callback is being executed.
---Caller must ensure that callback performs the same or functionally equivalent actions.
---
---@param context string identifies the callback to debounce
---@param timeout number ms to wait
---@param callback function to execute on completion
function M.debounce(context, timeout, callback)
  -- all execution here is done in a synchronous context; no thread safety required

  M.debouncers[context] = M.debouncers[context] or {}
  local debouncer = M.debouncers[context]

  -- cancel waiting or executing timer
  if debouncer.timer then
    timer_stop_close(debouncer.timer)
  end

  local timer = vim.loop.new_timer()
  if not timer then
    return
  end
  debouncer.timer = timer
  timer:start(timeout, 0, function()
    timer_stop_close(timer)

    -- reschedule when callback is running
    if debouncer.executing then
      M.debounce(context, timeout, callback)
      return
    end

    -- call back at a safe time
    debouncer.executing = true
    vim.schedule(function()
      callback()
      debouncer.executing = false

      -- no other timer waiting
      if debouncer.timer == timer then
        M.debouncers[context] = nil
      end
    end)
  end)
end

function M.focus_file(path)
  local _, i = M.find_node(require("nvim-tree.core").get_explorer().nodes, function(node)
    return node.absolute_path == path
  end)
  local explorer = require("nvim-tree.core").get_explorer()
  if explorer then
    explorer.view:set_cursor({ i + 1, 1 })
  end
end

---Focus node passed as parameter if visible, otherwise focus first visible parent.
---If none of the parents is visible focus root.
---If node is nil do nothing.
---@param node Node? node to focus
function M.focus_node_or_parent(node)
  local explorer = require("nvim-tree.core").get_explorer()

  if explorer == nil then
    return
  end

  while node do
    local found_node, i = M.find_node(explorer.nodes, function(node_)
      return node_.absolute_path == node.absolute_path
    end)

    if found_node or node.parent == nil then
      explorer.view:set_cursor({ i + 1, 1 })
      break
    end

    node = node.parent
  end
end

---@param path string
---@return integer|nil
---@return integer|nil
function M.get_win_buf_from_path(path)
  for _, w in pairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_buf_get_name(b) == path then
      return w, b
    end
  end
  return nil, nil
end

function M.clear_prompt()
  if vim.opt.cmdheight._value ~= 0 then
    vim.cmd("normal! :")
  end
end

--- Return a new table with values from array
---@param array table
---@return table
function M.array_shallow_clone(array)
  local to = {}
  for _, v in ipairs(array) do
    table.insert(to, v)
  end
  return to
end

--- Remove and return item from array if present.
---@param array table
---@param item any
---@return any|nil removed
function M.array_remove(array, item)
  if not array then
    return nil
  end
  for i, v in ipairs(array) do
    if v == item then
      table.remove(array, i)
      return v
    end
  end
end

---@param array table
---@return table
function M.array_remove_nils(array)
  return vim.tbl_filter(function(v)
    return v ~= nil
  end, array)
end

--- Is the buffer named NvimTree_[0-9]+ a tree? filetype is "NvimTree" or not readable file.
--- This is cheap, as the readable test should only ever be needed when resuming a vim session.
---@param bufnr number|nil may be 0 or nil for current
---@return boolean
function M.is_nvim_tree_buf(bufnr)
  if bufnr == nil then
    bufnr = 0
  end
  if vim.api.nvim_buf_is_valid(bufnr) then
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if vim.fn.fnamemodify(bufname, ":t"):match("^NvimTree_[0-9]+$") then
      if vim.bo[bufnr].filetype == "NvimTree" then
        return true
      elseif vim.fn.filereadable(bufname) == 0 then
        return true
      end
    end
  end
  return false
end

---First window that contains a buffer
---@param bufnr integer?
---@return integer? winid
function M.first_window_containing_buf(bufnr)
  if not bufnr then
    return nil
  end

  for _, winid in pairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(winid) == bufnr then
      return winid
    end
  end

  return nil
end

--- path is an executable file or directory
---@param absolute_path string
---@return boolean
function M.is_executable(absolute_path)
  if M.is_windows or M.is_wsl then
    --- executable detection on windows is buggy and not performant hence it is disabled
    return false
  else
    return vim.loop.fs_access(absolute_path, "X") or false
  end
end

---@class UtilEnumerateOptionsOpts
---@field keyset_opts vim.api.keyset.option
---@field was_set boolean? as per vim.api.keyset.get_option_info

---Option name/values
---@param opts UtilEnumerateOptionsOpts
---@return table<string, any>
function M.enumerate_options(opts)
  -- enumerate all options, limiting buf and win scopes
  return vim.tbl_map(function(info)
    if opts.keyset_opts.buf and info.scope ~= "buf" then
      return nil
    elseif opts.keyset_opts.win and info.scope ~= "win" then
      return nil
    else
      -- optional, lazy was_set check
      if not opts.was_set or vim.api.nvim_get_option_info2(info.name, opts.keyset_opts).was_set then
        return vim.api.nvim_get_option_value(info.name, opts.keyset_opts)
      else
        return nil
      end
    end
  end, vim.api.nvim_get_all_options_info())
end

return M
