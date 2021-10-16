local git_utils = require'nvim-tree.git.utils'
local updater = require'nvim-tree.git.tree-update'
local Runner = require'nvim-tree.git.runner'
local utils = require'nvim-tree.utils'

local M = {
  db = nil,
  toplevels = {},
}

function M.apply_updates(node)
  local filter_ignored = M.config.ignore and not require'nvim-tree.populate'.show_ignored
  updater.update(M.db, node, filter_ignored)
end

function M.handle_update(node)
  return function()
    M.apply_updates(node)
    require'nvim-tree.lib'.redraw()
  end
end

function M.get_loaded_toplevel(path)
  if not M.config.enable then
    return
  end
  local toplevel = git_utils.get_toplevel(path)
  if not toplevel or not M.toplevels[toplevel] then
    return
  end
  return toplevel
end

function M.set_toplevel(path, toplevel)
  if not M.config.enable then
    return
  end
  toplevel = toplevel or git_utils.get_toplevel(path)
  if not toplevel or M.toplevels[toplevel] ~= nil then
    return
  end

  M.toplevels[toplevel] = git_utils.show_untracked(toplevel)
end

local function clear()
  M.config.enable = false
  utils.echo_warning("git integration has been disabled, timeout was exceeded")
end

function M.run_git_status(toplevel, node)
  local show_untracked = M.toplevels[toplevel]
  local runner = Runner.new {
    db = M.db,
    toplevel = toplevel,
    show_untracked = show_untracked,
    with_ignored = M.config.ignore,
    timeout = M.config.timeout
  }

  runner:run(M.handle_update(node), clear)
end

function M.run(node, toplevel)
  if not M.config.enable then
    return
  end

  toplevel = toplevel or git_utils.get_toplevel(node.absolute_path)
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
    local info = "Git integration requires `tami5/sqlite.lua` to be installed (see :help nvim-tree.git)"
    utils.echo_warning(info)
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
      with_ignored = M.config.ignore,
      timeout = M.config.timeout
    }
    local tree = require'nvim-tree.lib'.Tree
    local node
    if utils.str_find(tree.cwd, toplevel) then
      node = { entries = tree.entries, absolute_path = tree.cwd }
    else
      node = utils.find_node(tree.entries, function(n)
        return toplevel == n.absolute_path or vim.startswith(n.absolute_path, toplevel)
      end)
    end
    if node then
      runner:run(M.handle_update(node), clear)
    end
  end
end

function M.cleanup()
  M.db:cleanup()
end

function M.setup(opts)
  M.config = {}
  M.config.enable = opts.git.enable
  M.config.ignore = opts.git.ignore
  M.config.timeout = opts.git.timeout
  -- TODO: for later use when refactoring the renderer
  -- M.config.show_highlights = opts.git.show_highlights
  -- M.config.show_icons = opts.git.show_icons
  -- M.config.icon_placement = opts.git.placement
  check_sqlite()

  if M.config.enable then
    M.db = require'nvim-tree.git.db'.new()
  end
end

return M
