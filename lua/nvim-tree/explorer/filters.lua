local utils = require "nvim-tree.utils"

local M = {
  ignore_list = {},
  exclude_list = {},
}

local function is_excluded(path)
  for _, node in ipairs(M.exclude_list) do
    if path:match(node) then
      return true
    end
  end
  return false
end

---Check if the given path should be ignored.
---@param path string Absolute path
---@param bufinfo table vim.fn.getbufinfo { bufloaded = 1, buflisted = 1 }
---@return boolean
function M.should_ignore(path, bufinfo)
  local basename = utils.path_basename(path)

  -- exclusions override all filters
  if is_excluded(path) then
    return false
  end

  -- filter files with no open buffer and directories containing no open buffers
  if M.config.filter_no_buffer and type(bufinfo) == "table" then
    for _, buf in ipairs(bufinfo) do
      if buf.name:find(path, 1, true) then
        return false
      end
    end
    return true
  end

  -- filter dotfiles
  if M.config.filter_dotfiles then
    if basename:sub(1, 1) == "." then
      return true
    end
  end

  if not M.config.filter_custom then
    return false
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

function M.should_ignore_git(path, status)
  if type(status) ~= "table" or type(status.files) ~= "table" or type(status.dirs) ~= "table" then
    return false
  end

  -- exclusions override all filters
  if is_excluded(path) then
    return false
  end

  -- default status to clean
  local st = status.files[path] or status.dirs[path] or "  "

  -- filter ignored; overrides clean as they are effectively dirty
  if M.config.filter_git_ignored and st == "!!" then
    return true
  end

  -- filter clean
  if M.config.filter_git_clean and st == "  " then
    return true
  end

  return false
end

function M.setup(opts)
  M.config = {
    filter_custom = true,
    filter_dotfiles = opts.filters.dotfiles,
    filter_git_ignored = opts.git.ignore,
    filter_git_clean = opts.filters.git_clean,
    filter_no_buffer = opts.filters.no_buffer,
  }

  M.ignore_list = {}
  M.exclude_list = opts.filters.exclude

  local custom_filter = opts.filters.custom
  if custom_filter and #custom_filter > 0 then
    for _, filter_name in pairs(custom_filter) do
      M.ignore_list[filter_name] = true
    end
  end
end

return M
