local utils = require("nvim-tree.utils")
local FILTER_REASON = require("nvim-tree.enum").FILTER_REASON

local Class = require("nvim-tree.classic")

---@alias FilterType "custom" | "dotfiles" | "git_ignored" | "git_clean" | "no_buffer" | "no_bookmark"

---@class (exact) Filters: Class
---@field enabled boolean
---@field state table<FilterType, boolean>
---@field private explorer Explorer
---@field private exclude_list string[] filters.exclude
---@field private ignore_list table<string, boolean> filters.custom string table
---@field private custom_function (fun(absolute_path: string): boolean)|nil filters.custom function
local Filters = Class:extend()

---@class Filters
---@overload fun(args: FiltersArgs): Filters

---@class (exact) FiltersArgs
---@field explorer Explorer

---@protected
---@param args FiltersArgs
function Filters:new(args)
  self.explorer        = args.explorer
  self.ignore_list     = {}
  self.exclude_list    = self.explorer.opts.filters.exclude
  self.custom_function = nil

  self.enabled         = self.explorer.opts.filters.enable
  self.state           = {
    custom      = true,
    dotfiles    = self.explorer.opts.filters.dotfiles,
    git_ignored = self.explorer.opts.filters.git_ignored,
    git_clean   = self.explorer.opts.filters.git_clean,
    no_buffer   = self.explorer.opts.filters.no_buffer,
    no_bookmark = self.explorer.opts.filters.no_bookmark,
  }

  local custom_filter  = self.explorer.opts.filters.custom
  if type(custom_filter) == "function" then
    self.custom_function = custom_filter
  else
    if custom_filter and #custom_filter > 0 then
      for _, filter_name in pairs(custom_filter) do
        self.ignore_list[filter_name] = true
      end
    end
  end
end

---@private
---@param path string
---@return boolean
function Filters:is_excluded(path)
  for _, node in ipairs(self.exclude_list) do
    if path:match(node) then
      return true
    end
  end
  return false
end

---Check if the given path is git clean/ignored
---@private
---@param path string Absolute path
---@param project GitProject from prepare
---@return boolean
function Filters:git(path, project)
  if type(project) ~= "table" or type(project.files) ~= "table" or type(project.dirs) ~= "table" then
    return false
  end

  -- default status to clean
  local xy = project.files[path]
  xy = xy or project.dirs.direct[path] and project.dirs.direct[path][1]
  xy = xy or project.dirs.indirect[path] and project.dirs.indirect[path][1]

  -- filter ignored; overrides clean as they are effectively dirty
  if self.state.git_ignored and xy == "!!" then
    return true
  end

  -- filter clean
  if self.state.git_clean and not xy then
    return true
  end

  return false
end

---Check if the given path has no listed buffer
---@private
---@param path string Absolute path
---@param bufinfo table vim.fn.getbufinfo { buflisted = 1 }
---@return boolean
function Filters:buf(path, bufinfo)
  if not self.state.no_buffer or type(bufinfo) ~= "table" then
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

---@private
---@param path string
---@return boolean
function Filters:dotfile(path)
  return self.state.dotfiles and utils.path_basename(path):sub(1, 1) == "."
end

---Bookmark is present
---@private
---@param path string
---@param path_type string|nil filetype of path
---@param bookmarks table<string, string|nil> path, filetype table of bookmarked files
---@return boolean
function Filters:bookmark(path, path_type, bookmarks)
  if not self.state.no_bookmark then
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

---@private
---@param path string
---@return boolean
function Filters:custom(path)
  if not self.state.custom then
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

  local idx = path:match(".+()%.[^.]+$")
  if idx then
    if self.ignore_list["*" .. string.sub(path, idx)] == true then
      return true
    end
  end

  return false
end

---Prepare arguments for should_filter. This is done prior to should_filter for efficiency reasons.
---@param project GitProject? optional results of git.load_projects(...)
---@return table
--- project: reference
--- bufinfo: empty unless no_buffer set: vim.fn.getbufinfo { buflisted = 1 }
--- bookmarks: absolute paths to boolean
function Filters:prepare(project)
  local status = {
    project = project or {},
    bufinfo = {},
    bookmarks = {},
  }

  if self.state.no_buffer then
    status.bufinfo = vim.fn.getbufinfo({ buflisted = 1 })
  end

  local explorer = require("nvim-tree.core").get_explorer()
  if explorer then
    for _, node in pairs(explorer.marks:list()) do
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
  if not self.enabled then
    return false
  end

  -- exclusions override all filters
  if self:is_excluded(path) then
    return false
  end

  return self:git(path, status.project)
    or self:buf(path, status.bufinfo)
    or self:dotfile(path)
    or self:custom(path)
    or self:bookmark(path, fs_stat and fs_stat.type, status.bookmarks)
end

--- Check if the given path should be filtered, and provide the reason why it was
---@param path string Absolute path
---@param fs_stat uv.fs_stat.result|nil fs_stat of file
---@param status table from prepare
---@return FILTER_REASON
function Filters:should_filter_as_reason(path, fs_stat, status)
  if not self.enabled then
    return FILTER_REASON.none
  end

  if self:is_excluded(path) then
    return FILTER_REASON.none
  end

  if self:git(path, status.project) then
    return FILTER_REASON.git
  elseif self:buf(path, status.bufinfo) then
    return FILTER_REASON.buf
  elseif self:dotfile(path) then
    return FILTER_REASON.dotfile
  elseif self:custom(path) then
    return FILTER_REASON.custom
  elseif self:bookmark(path, fs_stat and fs_stat.type, status.bookmarks) then
    return FILTER_REASON.bookmark
  else
    return FILTER_REASON.none
  end
end

---Toggle a type and refresh
---@private
---@param type FilterType? nil to disable all
function Filters:toggle(type)
  if not type or self.state[type] == nil then
    self.enabled = not self.enabled
  else
    self.state[type] = not self.state[type]
  end

  local node = self.explorer:get_node_at_cursor()
  self.explorer:reload_explorer()
  if node then
    utils.focus_node_or_parent(node)
  end
end

return Filters
