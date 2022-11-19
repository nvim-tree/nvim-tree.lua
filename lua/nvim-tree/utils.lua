local Iterator = require "nvim-tree.iterators.node-iterator"
local notify = require "nvim-tree.notify"

local M = {
  debouncers = {},
}

M.is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win32unix" == 1
M.is_wsl = vim.fn.has "wsl" == 1

function M.path_to_matching_str(path)
  return path:gsub("(%-)", "(%%-)"):gsub("(%.)", "(%%.)"):gsub("(%_)", "(%%_)")
end

function M.str_find(haystack, needle)
  return vim.fn.stridx(haystack, needle) ~= -1
end

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
function M.path_join(paths)
  return table.concat(vim.tbl_map(M.path_remove_trailing, paths), path_separator)
end

function M.path_split(path)
  return path:gmatch("[^" .. path_separator .. "]+" .. path_separator .. "?")
end

---Get the basename of the given path.
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

  return path .. path_separator
end

function M.path_remove_trailing(path)
  local p, _ = path:gsub(path_separator .. "$", "")
  return p
end

M.path_separator = path_separator

-- get the node and index of the node from the tree that matches the predicate.
-- The explored nodes are those displayed on the view.
-- @param nodes list of node
-- @param fn    function(node): boolean
function M.find_node(nodes, fn)
  local node, i = Iterator.builder(nodes)
    :matcher(fn)
    :recursor(function(node)
      return node.open and #node.nodes > 0 and node.nodes
    end)
    :iterate()
  i = require("nvim-tree.view").is_root_folder_visible() and i or i - 1
  i = require("nvim-tree.live-filter").filter and i + 1 or i
  return node, i
end

-- get the node in the tree state depending on the absolute path of the node
-- (grouped or hidden too)
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

-- get the highest parent of grouped nodes
function M.get_parent_of_group(node_)
  local node = node_
  while node.parent and node.parent.group_next do
    node = node.parent
  end
  return node
end

-- return visible nodes indexed by line
-- @param nodes_all list of node
-- @param line_start first index
---@return table
function M.get_nodes_by_line(nodes_all, line_start)
  local nodes_by_line = {}
  local line = line_start

  Iterator.builder(nodes_all)
    :applier(function(node)
      nodes_by_line[line] = node
      line = line + 1
    end)
    :recursor(function(node)
      return node.open == true and node.nodes
    end)
    :iterate()

  return nodes_by_line
end

---Matching executable files in Windows.
---@param ext string
---@return boolean
function M.is_windows_exe(ext)
  if not M.pathexts then
    if not vim.env.PATHEXT then
      return false
    end

    local wexe = vim.split(vim.env.PATHEXT:gsub("%.", ""), ";")
    M.pathexts = {}
    for _, v in pairs(wexe) do
      M.pathexts[v] = true
    end
  end

  return M.pathexts[ext:upper()]
end

--- Check whether path maps to Windows filesystem mounted by WSL
-- @param path string
-- @return boolean
function M.is_wsl_windows_fs_path(path)
  -- Run 'wslpath' command to try translating WSL path to Windows path.
  -- Consume stderr output as well because 'wslpath' can produce permission
  -- errors on some files (e.g. temporary files in root of system drive).
  local handle = io.popen('wslpath -w "' .. path .. '" 2>/dev/null')
  if handle then
    local output = handle:read "*a"
    handle:close()

    return string.find(output, "^\\\\wsl$\\") == nil
  end

  return false
end

--- Check whether extension is Windows executable under WSL
-- @param ext string
-- @return boolean
function M.is_wsl_windows_fs_exe(ext)
  if not vim.env.PATHEXT then
    -- Extract executable extensions from within WSL.
    -- Redirect stderr to null to silence warnings when
    -- Windows command is executed from Linux filesystem:
    -- > CMD.EXE was started with the above path as the current directory.
    -- > UNC paths are not supported. Defaulting to Windows directory.
    local handle = io.popen 'cmd.exe /c "echo %PATHEXT%" 2>/dev/null'
    if handle then
      vim.env.PATHEXT = handle:read "*a"
      handle:close()
    end
  end

  return M.is_windows_exe(ext)
end

function M.rename_loaded_buffers(old_path, new_path)
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      local exact_match = buf_name == old_path
      local child_match = (
        buf_name:sub(1, #old_path) == old_path and buf_name:sub(#old_path + 1, #old_path + 1) == path_separator
      )
      if exact_match or child_match then
        vim.api.nvim_buf_set_name(buf, new_path .. buf_name:sub(#old_path + 1))
        -- to avoid the 'overwrite existing file' error message on write for
        -- normal files
        if vim.api.nvim_buf_get_option(buf, "buftype") == "" then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd "silent! write!"
            vim.cmd "edit"
          end)
        end
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
  if M.is_windows and path:match "^%a:" then
    return path:sub(1, 1):upper() .. path:sub(2)
  end
  return path
end

-- Create empty sub-tables if not present
-- @param tbl to create empty inside of
-- @param path dot separated string of sub-tables
-- @return deepest sub-table
function M.table_create_missing(tbl, path)
  if tbl == nil then
    return nil
  end

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
--- @param src table to copy from
--- @param src_path string dot separated string of sub-tables
--- @param src_pos string value pos
--- @param dst table to copy to
--- @param dst_path string dot separated string of sub-tables, created when missing
--- @param dst_pos string value pos
--- @param remove boolean default true
function M.move_missing_val(src, src_path, src_pos, dst, dst_path, dst_pos, remove)
  if remove == nil then
    remove = true
  end

  local ok, err = pcall(vim.validate, {
    src = { src, "table" },
    src_path = { src_path, "string" },
    src_pos = { src_pos, "string" },
    dst = { dst, "table" },
    dst_path = { dst_path, "string" },
    dst_pos = { dst_pos, "string" },
    remove = { remove, "boolean" },
  })
  if not ok then
    notify.warn("move_missing_val: " .. (err or "invalid arguments"))
    return
  end

  for pos in string.gmatch(src_path, "([^%.]+)%.*") do
    if src[pos] and type(src[pos]) == "table" then
      src = src[pos]
    else
      src = nil
      break
    end
  end
  local src_val = src and src[src_pos]
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

function M.format_bytes(bytes)
  local units = { "B", "K", "M", "G", "T" }

  bytes = math.max(bytes, 0)
  local pow = math.floor((bytes and math.log(bytes) or 0) / math.log(1024))
  pow = math.min(pow, #units)

  local value = bytes / (1024 ^ pow)
  value = math.floor((value * 10) + 0.5) / 10

  pow = pow + 1

  return (units[pow] == nil) and (bytes .. "B") or (value .. units[pow])
end

function M.key_by(tbl, key)
  local keyed = {}
  for _, val in ipairs(tbl) do
    keyed[val[key]] = val
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
  require("nvim-tree.view").set_cursor { i + 1, 1 }
end

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
    vim.cmd "normal! :"
  end
end

-- return a new table with values from array
function M.array_shallow_clone(array)
  local to = {}
  for _, v in ipairs(array) do
    table.insert(to, v)
  end
  return to
end

-- remove item from array if it exists
function M.array_remove(array, item)
  for i, v in ipairs(array) do
    if v == item then
      table.remove(array, i)
      break
    end
  end
end

function M.array_remove_nils(array)
  return vim.tbl_filter(function(v)
    return v ~= nil
  end, array)
end

function M.inject_node(f)
  return function()
    f(require("nvim-tree.lib").get_node_at_cursor())
  end
end

---Is the buffer named NvimTree_[0-9]+ a tree? filetype is "NvimTree" or not readable file.
---This is cheap, as the readable test should only ever be needed when resuming a vim session.
---@param bufnr number may be 0 or nil for current
---@return boolean
function M.is_nvim_tree_buf(bufnr)
  if bufnr == nil then
    bufnr = 0
  end
  if vim.fn.bufexists(bufnr) then
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if vim.fn.fnamemodify(bufname, ":t"):match "^NvimTree_[0-9]+$" then
      if vim.bo[bufnr].filetype == "NvimTree" then
        return true
      elseif vim.fn.filereadable(bufname) == 0 then
        return true
      end
    end
  end
  return false
end

return M
