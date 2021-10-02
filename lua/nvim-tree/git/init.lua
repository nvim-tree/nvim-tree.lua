local utils = require'nvim-tree.git.utils'
local updater = require'nvim-tree.git.tree-update'
local Runner = require'nvim-tree.git.runner'

local M = {
  db = nil,
  toplevels = {},
}

function M.handle_update(node)
  return function()
    local filter_ignored = M.config.ignore and not require'nvim-tree.populate'.show_ignored
    updater.update(M.db, node, filter_ignored)
    require'nvim-tree.lib'.redraw()
  end
end

function M.set_toplevel(path, toplevel)
  if not M.config.enable then
    return
  end
  toplevel = toplevel or utils.get_toplevel(path)
  if not toplevel or M.toplevels[toplevel] ~= nil then
    return
  end

  M.toplevels[toplevel] = utils.show_untracked(toplevel)
end

function M.run_git_status(toplevel, node)
  local show_untracked = M.toplevels[toplevel]
  local runner = Runner.new {
    db = M.db,
    toplevel = toplevel,
    show_untracked = show_untracked,
    with_ignored = M.config.ignore
  }

  runner:run(M.handle_update(node))
end

function M.run(node)
  if not M.config.enable then
    return
  end

  local toplevel = utils.get_toplevel(node.absolute_path)
  if not toplevel then
    return
  end

  if M.toplevels[toplevel] == nil then
    M.set_toplevel(nil, toplevel)
    M.run_git_status(toplevel, node)
  else
    M.handle_update(node)()
  end
end

local function check_sqlite()
  local has_sqlite = pcall(require, 'sqlite')
  if M.config.enable and not has_sqlite then
    local info = "[NvimTree] Git integration requires sqlite.lua to be installed (see :help nvim-tree-git)"
    require'nvim-tree.utils'.echo_warning(info)
    M.config.enable = false
  end
end

function M.reload()
  if not M.config.enable then
    return
  end

  for toplevel, show_untracked in pairs(M.toplevels) do
    local runner = Runner.new {
      db = M.db,
      toplevel = toplevel,
      show_untracked = show_untracked,
      with_ignored = M.config.ignore
    }
    local tree = require'nvim-tree.lib'.Tree
    local node
    if tree.cwd == toplevel then
      node = { entries = tree.entries, absolute_path = tree.cwd }
    else
      node = require'nvim-tree.utils'.find_node(tree.entries, function(n)
        return toplevel == n.absolute_path
      end)
    end
    if node then
      runner:run(M.handle_update(node))
    end
  end
end

function M.cleanup()
  M.db:cleanup()
end

function M.setup(opts)
  M.config = {}
  M.config.enable = opts.git.enable
  M.config.show_highlights = opts.git.show_highlights
  M.config.show_icons = opts.git.show_icons
  M.config.icon_placement = opts.git.placement
  M.config.ignore = opts.git.ignore
  check_sqlite()

  if M.config.enable then
    M.db = require'nvim-tree.git.db'.new()
  end
end

return M
