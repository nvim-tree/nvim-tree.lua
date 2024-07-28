local utils = require "nvim-tree.utils"
local FILTER_REASON = require("nvim-tree.enum").FILTER_REASON

---@class Filters to handle all opts.filters and related API
---@field config table hydrated user opts.filters
---@field private explorer Explorer
---@field private exclude_list string[] filters.exclude
---@field private ignore_list string[] filters.custom string table
---@field private custom_function (fun(absolute_path: string): boolean)|nil filters.custom function
local Filters = {}

---@param opts table user options
---@param explorer Explorer
---@return Filters
function Filters:new(opts, explorer)
  local o = {
    explorer = explorer,
    ignore_list = {},
    exclude_list = opts.filters.exclude,
    custom_function = nil,
    config = {
      enable = opts.filters.enable,
      filter_custom = true,
      filter_dotfiles = opts.filters.dotfiles,
      filter_git_ignored = opts.filters.git_ignored,
      filter_git_clean = opts.filters.git_clean,
      filter_no_buffer = opts.filters.no_buffer,
      filter_no_bookmark = opts.filters.no_bookmark,
    },
  }

  local custom_filter = opts.filters.custom
  if type(custom_filter) == "function" then
    o.custom_function = custom_filter
  else
    if custom_filter and #custom_filter > 0 then
      for _, filter_name in pairs(custom_filter) do
        o.ignore_list[filter_name] = true
      end
    end
  end
  setmetatable(o, self)
  self.__index = self
  return o
end

---@param path string
---@return boolean
local function is_excluded(self, path)
  for _, node in ipairs(self.exclude_list) do
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
local function git(self, path, git_status)
  if type(git_status) ~= "table" or type(git_status.files) ~= "table" or type(git_status.dirs) ~= "table" then
    return false
  end

  -- default status to clean
  local status = git_status.files[path]
  status = status or git_status.dirs.direct[path] and git_status.dirs.direct[path][1]
  status = status or git_status.dirs.indirect[path] and git_status.dirs.indirect[path][1]

  -- filter ignored; overrides clean as they are effectively dirty
  if self.config.filter_git_ignored and status == "!!" then
    return true
  end

  -- filter clean
  if self.config.filter_git_clean and not status then
    return true
  end

  return false
end

---Check if the given path has no listed buffer
---@param path string Absolute path
---@param bufinfo table vim.fn.getbufinfo { buflisted = 1 }
---@return boolean
local function buf(self, path, bufinfo)
  if not self.config.filter_no_buffer or type(bufinfo) ~= "table" then
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
local function dotfile(self, path)
  return self.config.filter_dotfiles and utils.path_basename(path):sub(1, 1) == "."
end

---@param path string
---@param path_type string|nil filetype of path
---@param bookmarks table<string, string|nil> path, filetype table of bookmarked files
local function bookmark(self, path, path_type, bookmarks)
  if not self.config.filter_no_bookmark then
    return false
  end
  -- if bookmark is empty, we should see a empty filetree
  if next(bookmarks) == nil then
    return true
  end

  local mark_parent = utils.path_add_trailing(path)
  for mark, mark_type in pairs(bookmarks) do
    if path == mark then
      return false
    end

    if path_type == "directory" then
      -- check if path is mark's parent
      if vim.fn.stridx(mark, mark_parent) == 0 then
        return false
      end
    end
    if mark_type == "directory" then
      -- check if mark is path's parent
      local path_parent = utils.path_add_trailing(mark)
      if vim.fn.stridx(path, path_parent) == 0 then
        return false
      end
    end
  end

  return true
end

---@param path string
---@return boolean
local function custom(self, path)
  if not self.config.filter_custom then
    return false
  end

  local basename = utils.path_basename(path)

  -- filter user's custom function
  if self.custom_function and self.custom_function(path) then
    return true
  end

  -- filter custom regexes
  local relpath = utils.path_relative(path, vim.loop.cwd())
  for pat, _ in pairs(self.ignore_list) do
    if vim.fn.match(relpath, pat) ~= -1 or vim.fn.match(basename, pat) ~= -1 then
      return true
    end
  end

  local idx = path:match ".+()%.[^.]+$"
  if idx then
    if self.ignore_list["*" .. string.sub(path, idx)] == true then
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
function Filters:prepare(git_status)
  local status = {
    git_status = git_status or {},
    bufinfo = {},
    bookmarks = {},
  }

  if self.config.filter_no_buffer then
    status.bufinfo = vim.fn.getbufinfo { buflisted = 1 }
  end

  local explorer = require("nvim-tree.core").get_explorer()
  if explorer then
    for _, node in pairs(explorer.marks:get_marks()) do
      status.bookmarks[node.absolute_path] = node.type
    end
  end

  return status
end

---Check if the given path should be filtered.
---@param path string Absolute path
---@param fs_stat uv.fs_stat.result|nil fs_stat of file
---@param status table from prepare
---@return boolean
function Filters:should_filter(path, fs_stat, status)
  if not self.config.enable then
    return false
  end

  -- exclusions override all filters
  if is_excluded(self, path) then
    return false
  end

  return git(self, path, status.git_status)
    or buf(self, path, status.bufinfo)
    or dotfile(self, path)
    or custom(self, path)
    or bookmark(self, path, fs_stat and fs_stat.type, status.bookmarks)
end

--- Check if the given path should be filtered, and provide the reason why it was
---@param path string Absolute path
---@param fs_stat uv.fs_stat.result|nil fs_stat of file
---@param status table from prepare
---@return FILTER_REASON
function Filters:should_filter_as_reason(path, fs_stat, status)
  if not self.config.enable then
    return FILTER_REASON.none
  end

  if is_excluded(self, path) then
    return FILTER_REASON.none
  end

  if git(self, path, status.git_status) then
    return FILTER_REASON.git
  elseif buf(self, path, status.bufinfo) then
    return FILTER_REASON.buf
  elseif dotfile(self, path) then
    return FILTER_REASON.dotfile
  elseif custom(self, path) then
    return FILTER_REASON.custom
  elseif bookmark(self, path, fs_stat and fs_stat.type, status.bookmarks) then
    return FILTER_REASON.bookmark
  else
    return FILTER_REASON.none
  end
end

return Filters
