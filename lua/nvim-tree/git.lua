local a = vim.api
local uv = vim.loop
local utils = require'nvim-tree.utils'

local M = {}

local map_to_icon_name = {
  ['?'] = 'untracked',
-- 'staged is M on index'
  M = 'unstaged',
  A = '',
  D = 'deleted',
  R = 'renamed',
  U = 'unmerged',
  [' '] = ''
  -- C = 'copy',
}

local function map_status_to_icons(status, cwd)
  local t = {}
  for _, s in ipairs(status) do
    local path = utils.path_join(cwd, s:sub(4))
    local i1 = M.opts.icons[map_to_icon_name[s:sub(1,1)]] or ''
    local i2 = M.opts.icons[map_to_icon_name[s:sub(2,2)]] or ''
    t[path] = i1..i2

    -- this is bullshit, rewrite please
    while path ~= cwd do
      path = path:gsub('/[^/]*$', '')
      local icons = t[path]
      if icons then
        if not icons:find(i1) then
          t[path] = icons..' '..i1
        end
        if not icons:find(i2) then
          t[path] = t[path]..i2
        end
      else
        t[path] = i1..i2
      end
    end
  end
  return t
end

function M.gitify(entries, cwd)
  if not M.opts.show.icons or not M.opts.show.highlight then
    return entries
  end

  local git_root = vim.fn.system("cd '"..cwd.."' && git rev-parse --show-toplevel"):sub(0, -2)
  if git_root:match("fatal") then
    return entries
  end

  local status = vim.fn.systemlist("cd '"..git_root.."' && git status --porcelain=1 -u")
  local mapped_statuses = map_status_to_icons(status, git_root)
  -- dump(mapped_statuses)

  for _, entry in pairs(entries) do
    local s = mapped_statuses[entry.absolute_path]
    if s then
      entry.git_icon = s
    end
  end

  -- dump(entries)

  return entries
end

function M.configure(opts)
  M.opts = opts.git
end

return M
