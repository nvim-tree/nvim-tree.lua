local has_notify, notify = pcall(require, "notify")

local a = vim.api
local uv = vim.loop

local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {
  debouncers = {},
}

M.is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win32unix" == 1

function M.path_to_matching_str(path)
  return path:gsub("(%-)", "(%%-)"):gsub("(%.)", "(%%.)"):gsub("(%_)", "(%%_)")
end

function M.warn(msg)
  vim.schedule(function()
    if has_notify then
      notify(msg, vim.log.levels.WARN, { title = "NvimTree" })
    else
      vim.notify("[NvimTree] " .. msg, vim.log.levels.WARN)
    end
  end)
end

function M.str_find(haystack, needle)
  return vim.fn.stridx(haystack, needle) ~= -1
end

function M.read_file(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then
    return ""
  end
  local stat = uv.fs_fstat(fd)
  if not stat then
    return ""
  end
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
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

function M.clear_prompt()
  vim.api.nvim_command "normal! :"
end

function M.get_user_input_char()
  local c = vim.fn.getchar()
  while type(c) ~= "number" do
    c = vim.fn.getchar()
  end
  return vim.fn.nr2char(c)
end

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
local PATHEXT = vim.env.PATHEXT or ""
local wexe = vim.split(PATHEXT:gsub("%.", ""), ";")
local pathexts = {}
for _, v in pairs(wexe) do
  pathexts[v] = true
end

function M.is_windows_exe(ext)
  return pathexts[ext:upper()]
end

function M.rename_loaded_buffers(old_path, new_path)
  for _, buf in pairs(a.nvim_list_bufs()) do
    if a.nvim_buf_is_loaded(buf) then
      local buf_name = a.nvim_buf_get_name(buf)
      local exact_match = buf_name == old_path
      local child_match = (
        buf_name:sub(1, #old_path) == old_path and buf_name:sub(#old_path + 1, #old_path + 1) == path_separator
      )
      if exact_match or child_match then
        a.nvim_buf_set_name(buf, new_path .. buf_name:sub(#old_path + 1))
        -- to avoid the 'overwrite existing file' error message on write for
        -- normal files
        if a.nvim_buf_get_option(buf, "buftype") == "" then
          a.nvim_buf_call(buf, function()
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

-- Move a value from src to dst if value is nil on dst
-- @param src to copy from
-- @param src_path dot separated string of sub-tables
-- @param src_pos value pos
-- @param dst to copy to
-- @param dst_path dot separated string of sub-tables, created when missing
-- @param dst_pos value pos
function M.move_missing_val(src, src_path, src_pos, dst, dst_path, dst_pos)
  local ok, err = pcall(vim.validate, {
    src = { src, "table" },
    src_path = { src_path, "string" },
    src_pos = { src_pos, "string" },
    dst = { dst, "table" },
    dst_path = { dst_path, "string" },
    dst_pos = { dst_pos, "string" },
  })
  if not ok then
    M.warn("move_missing_val: " .. (err or "invalid arguments"))
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

  src[src_pos] = nil
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

local function timer_stop_close(timer)
  if timer:is_active() then
    timer:stop()
  end
  if not timer:is_closing() then
    timer:close()
  end
end

---Execute callback timeout ms after the lastest invocation with context.
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

  local timer = uv.new_timer()
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

return M
