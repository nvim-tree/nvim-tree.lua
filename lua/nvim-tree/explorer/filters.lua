local utils = require("nvim-tree.utils")
local FILTER_REASON = require("nvim-tree.enum").FILTER_REASON

local Class = require("nvim-tree.classic")

---@alias FilterType "custom" | "dotfiles" | "git_ignored" | "git_clean" | "no_buffer" | "no_bookmark"
---@alias GitFilterType "git_clean" | "git_ignored"

---@class FilterStatus
---@field project GitProject | nil
---@field bufinfo table
---@field bookmarks table

---@class (exact) Filters: Class
---@field enabled boolean
---@field state table<FilterType, boolean>
---@field api table<string, fun(self: Filters, path: string): boolean|nil>
---@field private explorer Explorer
---@field private exclude_list string[] filters.exclude
---@field private ignore_list table<string, boolean> filters.custom string table
---@field private custom_function (fun(absolute_path: string): boolean)|nil filters.custom function
---@field protected status FilterStatus
---@field private filter_cache table<string, FILTER_REASON>
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

  self.filter_cache = {}

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

--- Cache filter function results so subsequent calls to the same path in a loop
--- iteration are as fast as possible
---@private
---@param fn fun(self: Filters, path: string): boolean
---@param reason FILTER_REASON
---@return fun(self: Filters, path: string): boolean
local function cache_wrapper(fn, reason)

  ---@param self Filters
  ---@param path string
  ---@return FILTER_REASON
  ---@diagnostic disable:invisible
  local function inner(self, path)

    if self.filter_cache[reason] == nil then
      self.filter_cache[reason] = {}
    end

    if self.filter_cache[reason][path] == nil then
      self.filter_cache[reason][path] = fn(self, path)
    end

    return self.filter_cache[reason][path]
  end
  ---@diagnostic enable:invisible

  return inner
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
---@param filter_type GitFilterType
---@param path string Absolute path
---@param project GitProject from prepare
---@return boolean
function Filters:git(filter_type, path, project)
  if type(project) ~= "table" or type(project.files) ~= "table" or type(project.dirs) ~= "table" then
    return false
  end

  -- default status to clean
  local xy = project.files[path]
  xy = xy or project.dirs.direct[path] and project.dirs.direct[path][1]
  xy = xy or project.dirs.indirect[path] and project.dirs.indirect[path][1]

  if filter_type == "git_ignored" and xy == "!!" then
    return true
  end

  if filter_type == "git_clean" and not xy then
    return true
  end

  return false
end

---@param path string
---@return boolean
function Filters:git_clean(path)
  -- filter ignored; overrides clean as they are effectively dirty
  if self.state.git_ignored and self:git_ignored("path") then
    return true
  else
    return self:git("git_clean", path, self.status.project)
  end
end

---@param path string
---@return boolean
function Filters:git_ignored(path)
  return self:git("git_ignored", path, self.status.project)
end

---Check if the given path has no listed buffer
---@param path string Absolute path
---@return boolean
function Filters:buf(path)
  if type(self.status.bufinfo) ~= "table" then
    return false
  end

  -- filter files with no open buffer and directories containing no open buffers
  for _, b in ipairs(self.status.bufinfo) do
    if b.name == path or b.name:find(path .. "/", 1, true) then
      return false
    end
  end

  return true
end

---@param path string
---@return boolean
function Filters:dotfile(path)
  return utils.path_basename(path):sub(1, 1) == "."
end

---Bookmark is present
---@param path string
---@return boolean
function Filters:bookmark(path)
  local bookmarks = self.status.bookmarks

  -- if bookmark is empty, we should see a empty filetree
  if next(bookmarks) == nil then
    return true
  end

  local stat, _ = vim.loop.fs_stat(path)
  local path_type = stat and stat.type

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
function Filters:custom(path)
  -- filter user's custom function
  if type(self.custom_function) == "function" then
    return self.custom_function(path)
  end

  local basename = utils.path_basename(path)

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
  self.status = {
    project = project or {},
    bufinfo = {},
    bookmarks = {},
  }

  self.filter_cache = {}

  self.status.bufinfo = vim.fn.getbufinfo({ buflisted = 1 })

  local explorer = require("nvim-tree.core").get_explorer()
  if explorer then
    for _, node in pairs(explorer.marks:list()) do
      self.status.bookmarks[node.absolute_path] = node.type
    end
  end

  return self.status
end

---Check if the given path should be filtered.
---@param path string Absolute path
---@return boolean
function Filters:should_filter(path)
  if not self.enabled then
    return false
  end

  -- exclusions override all filters
  if self:is_excluded(path) then
    return false
  end

  return (self.state.custom and self:custom(path))
    or (self.state.git_clean and self:git_clean(path))
    or (self.state.git_ignored and self:git_ignored(path))
    or (self.state.no_buffer and self:buf(path))
    or (self.state.dotfiles and self:dotfile(path))
    or (self.state.no_bookmark and self:bookmark(path))
end

--- Check if the given path should be filtered, and provide the reason why it was
---@param path string Absolute path
---@return FILTER_REASON
function Filters:should_filter_as_reason(path)
  if not self.enabled then
    return FILTER_REASON.none
  end

  if self:is_excluded(path) then
    return FILTER_REASON.none
  end

  if not self:should_filter(path) then
    return FILTER_REASON.none
  end

  if self.state.custom and self:custom(path) then
    return FILTER_REASON.custom

  elseif self.state.git_clean and self:git_clean(path) then
    return FILTER_REASON.git_clean

  elseif self.state.git_ignored and self:git_ignored(path) then
    return FILTER_REASON.git_ignore

  elseif self.state.no_buffer and self:buf(path) then
    return FILTER_REASON.buf

  elseif self.state.dotfiles and self:dotfile(path) then
    return FILTER_REASON.dotfile

  elseif self.state.no_bookmark and self:bookmark(path) then
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
    self.explorer:focus_node_or_parent(node)
  end
end

---@diagnostic disable:inject-field
Filters.custom      = cache_wrapper(Filters.custom, FILTER_REASON.custom)
Filters.dotfile     = cache_wrapper(Filters.dotfile, FILTER_REASON.dotfile)
Filters.git_ignored = cache_wrapper(Filters.git_ignored, FILTER_REASON.git_ignore)
Filters.git_clean   = cache_wrapper(Filters.git_clean, FILTER_REASON.git_clean)
Filters.buf         = cache_wrapper(Filters.buf, FILTER_REASON.buf)
Filters.bookmark    = cache_wrapper(Filters.bookmark, FILTER_REASON.bookmark)
---@diagnostic enable:inject-field

Filters.api = {
  custom      = Filters.custom,
  dotfile     = Filters.dotfile,
  git_ignored = Filters.git_ignored,
  git_clean   = Filters.git_clean,
  no_buffer   = Filters.buf,
  no_bookmark = Filters.bookmark,
}

return Filters
