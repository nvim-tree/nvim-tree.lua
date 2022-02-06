local api = vim.api
local luv = vim.loop

local utils = require'nvim-tree.utils'
local eutils = require'nvim-tree.explorer.utils'
local builders = require'nvim-tree.explorer.node-builders'

local M = {}

function M.explore(nodes, cwd, parent_node, status)
  local handle = luv.fs_scandir(cwd)
  if type(handle) == 'string' then
    api.nvim_err_writeln(handle)
    return
  end

  local dirs = {}
  local links = {}
  local files = {}

  while true do
    local name, t = luv.fs_scandir_next(handle)
    if not name then break end

    local abs = utils.path_join({cwd, name})
    if not eutils.should_ignore(abs) and not eutils.should_ignore_git(abs, status.files) then
      if not t then
        local stat = luv.fs_stat(abs)
        t = stat and stat.type
      end

      if t == 'directory' then
        table.insert(dirs, name)
      elseif t == 'file' then
        table.insert(files, name)
      elseif t == 'link' then
        table.insert(links, name)
      end
    end
  end

  local parent_node_ignored = parent_node and parent_node.git_status == '!!'
  -- Group empty dirs
  if parent_node and vim.g.nvim_tree_group_empty == 1 then
    if eutils.should_group(cwd, dirs, files, links) then
      local child_node
      if dirs[1] then child_node = builders.folder(cwd, dirs[1], status, parent_node_ignored) end
      if links[1] then child_node = builders.link(cwd, links[1], status, parent_node_ignored) end
      if luv.fs_access(child_node.absolute_path, 'R') then
        parent_node.group_next = child_node
        child_node.git_status = parent_node.git_status
        M.explore(nodes, child_node.absolute_path, child_node, status)
        return
      end
    end
  end

  for _, dirname in ipairs(dirs) do
    local dir = builders.folder(cwd, dirname, status, parent_node_ignored)
    if luv.fs_access(dir.absolute_path, 'R') then
      table.insert(nodes, dir)
    end
  end

  for _, linkname in ipairs(links) do
    local link = builders.link(cwd, linkname, status, parent_node_ignored)
    if link.link_to ~= nil then
      table.insert(nodes, link)
    end
  end

  for _, filename in ipairs(files) do
    local file = builders.file(cwd, filename, status, parent_node_ignored)
    table.insert(nodes, file)
  end

  utils.merge_sort(nodes, eutils.node_comparator)
end

return M
