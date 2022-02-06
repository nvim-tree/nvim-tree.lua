local uv = vim.loop
local utils = require'nvim-tree.utils'

local M = {
  ignore_list = {},
  exclude_list = {},
}

-- Returns true if there is either exactly 1 dir, or exactly 1 symlink dir. Otherwise, false.
-- @param cwd Absolute path to the parent directory
-- @param dirs List of dir names
-- @param files List of file names
-- @param links List of symlink names
function M.should_group(cwd, dirs, files, links)
  if #dirs == 1 and #files == 0 and #links == 0 then
    return true
  end

  if #dirs == 0 and #files == 0 and #links == 1 then
    local absolute_path = utils.path_join({ cwd, links[1] })
    local link_to = uv.fs_realpath(absolute_path)
    return (link_to ~= nil) and uv.fs_stat(link_to).type == 'directory'
  end

  return false
end

function M.node_comparator(a, b)
  if not (a and b) then
    return true
  end
  if a.nodes and not b.nodes then
    return true
  elseif not a.nodes and b.nodes then
    return false
  end

  return a.name:lower() <= b.name:lower()
end

---Check if the given path should be ignored.
---@param path string Absolute path
---@return boolean
function M.should_ignore(path)
  local basename = utils.path_basename(path)

  for _, node in ipairs(M.exclude_list) do
    if path:match(node) then
      return false
    end
  end

  if M.config.filter_dotfiles then
    if basename:sub(1, 1) == '.' then
      return true
    end
  end

  if not M.config.filter_ignored then
    return false
  end

  local relpath = utils.path_relative(path, vim.loop.cwd())
  if M.ignore_list[relpath] == true or M.ignore_list[basename] == true then
    return true
  end

  local idx = path:match(".+()%.[^.]+$")
  if idx then
    if M.ignore_list['*'..string.sub(path, idx)] == true then
      return true
    end
  end

  return false
end

function M.should_ignore_git(path, status)
  return M.config.filter_ignored
    and (M.config.filter_git_ignored and status and status[path] == '!!')
end

function M.setup(opts)
  M.config = {
    filter_ignored = true,
    filter_dotfiles = opts.filters.dotfiles,
    filter_git_ignored = opts.git.ignore,
  }

  M.exclude_list = opts.filters.exclude

  local custom_filter = opts.filters.custom
  if custom_filter and #custom_filter > 0 then
    for _, filter_name in pairs(custom_filter) do
      M.ignore_list[filter_name] = true
    end
  end
end

return M
