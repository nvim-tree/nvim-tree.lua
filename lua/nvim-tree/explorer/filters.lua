local utils = require "nvim-tree.utils"
local marks = require "nvim-tree.marks"

local M = {
  ignore_list = {},
  exclude_list = {},
  custom_function = nil,
}

---@param path string
---@return boolean
local function is_excluded(path)
  for _, node in ipairs(M.exclude_list) do
    if path:match(node) then
      return true
    end
  end
  return false
end

---Check if the given path is git clean/ignored
---@param path string Absolute path
---@param git_status table from prepare
---@return boolean
local function git(path, git_status)
  if type(git_status) ~= "table" or type(git_status.files) ~= "table" or type(git_status.dirs) ~= "table" then
    return false
  end

  -- default status to clean
  local status = git_status.files[path]
  status = status or git_status.dirs.direct[path] and git_status.dirs.direct[path][1]
  status = status or git_status.dirs.indirect[path] and git_status.dirs.indirect[path][1]

  -- filter ignored; overrides clean as they are effectively dirty
  if M.config.filter_git_ignored and status == "!!" then
    return true
  end

  -- filter clean
  if M.config.filter_git_clean and not status then
    return true
  end

  return false
end

---Check if the given path has no listed buffer
---@param path string Absolute path
---@param bufinfo table vim.fn.getbufinfo { buflisted = 1 }
---@return boolean
local function buf(path, bufinfo)
  if not M.config.filter_no_buffer or type(bufinfo) ~= "table" then
    return false
  end

  -- filter files with no open buffer and directories containing no open buffers
  for _, b in ipairs(bufinfo) do
    if b.name == path or b.name:find(path .. "/", 1, true) then
      return false
    end
  end

  return true
end

---@param path string
---@return boolean
local function dotfile(path)
  return M.config.filter_dotfiles and utils.path_basename(path):sub(1, 1) == "."
end

---@param path string
---@param bookmarks table<string, boolean> absolute paths bookmarked
local function bookmark(path, bookmarks)
  return M.config.filter_no_bookmark and not bookmarks[path]
end

---@param path string
---@return boolean
local function custom(path)
  if not M.config.filter_custom then
    return false
  end

  local basename = utils.path_basename(path)

  -- filter user's custom function
  if M.custom_function and M.custom_function(path) then
    return true
  end

  -- filter custom regexes
  local relpath = utils.path_relative(path, vim.loop.cwd())
  for pat, _ in pairs(M.ignore_list) do
    if vim.fn.match(relpath, pat) ~= -1 or vim.fn.match(basename, pat) ~= -1 then
      return true
    end
  end

  local idx = path:match ".+()%.[^.]+$"
  if idx then
    if M.ignore_list["*" .. string.sub(path, idx)] == true then
      return true
    end
  end

  return false
end

---Prepare arguments for should_filter. This is done prior to should_filter for efficiency reasons.
---@param git_status table|nil optional results of git.load_project_status(...)
---@return table
--- git_status: reference
--- bufinfo: empty unless no_buffer set: vim.fn.getbufinfo { buflisted = 1 }
--- bookmarks: absolute paths to boolean
function M.prepare(git_status)
  local status = {
    git_status = git_status or {},
    bufinfo = {},
    bookmarks = {},
  }

  if M.config.filter_no_buffer then
    status.bufinfo = vim.fn.getbufinfo { buflisted = 1 }
  end

  for _, node in pairs(marks.get_marks()) do
    status.bookmarks[node.absolute_path] = true
  end

  return status
end

---Check if the given path should be filtered.
---@param path string Absolute path
---@param status table from prepare
---@return boolean
function M.should_filter(path, status)
  -- exclusions override all filters
  if is_excluded(path) then
    return false
  end

  return git(path, status.git_status) or buf(path, status.bufinfo) or dotfile(path) or custom(path) or bookmark(path, status.bookmarks)
end

function M.setup(opts)
  M.config = {
    filter_custom = true,
    filter_dotfiles = opts.filters.dotfiles,
    filter_git_ignored = opts.filters.git_ignored,
    filter_git_clean = opts.filters.git_clean,
    filter_no_buffer = opts.filters.no_buffer,
    filter_no_bookmark = opts.filters.no_bookmark,
  }

  M.ignore_list = {}
  M.exclude_list = opts.filters.exclude

  local custom_filter = opts.filters.custom
  if type(custom_filter) == "function" then
    M.custom_function = custom_filter
  else
    if custom_filter and #custom_filter > 0 then
      for _, filter_name in pairs(custom_filter) do
        M.ignore_list[filter_name] = true
      end
    end
  end
end

return M
