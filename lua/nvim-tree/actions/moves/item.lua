local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local core = require "nvim-tree.core"
local lib = require "nvim-tree.lib"
local explorer_node = require "nvim-tree.explorer.node"
local diagnostics = require "nvim-tree.diagnostics"

local M = {}
local MAX_DEPTH = 100

---Return the status of the node or nil if no status, depending on the type of
---status.
---@param node table node to inspect
---@param what string type of status
---@return any|nil
local function get_status(node, what)
  if what == "git" then
    return explorer_node.get_git_status(node)
  elseif what == "diag" then
    return node.diag_status
  elseif what == "opened" then
    local opened_nb = vim.fn.bufloaded(node.absolute_path)
    if opened_nb == 0 then
      return nil
    else
      return opened_nb
    end
  end

  return nil
end

---Move to the next node that has a valid status. If none found, don't move.
---@param where string where to move (forwards or backwards)
---@param what string type of status
---@param skip_gitignored boolean default false
local function move(where, what, skip_gitignored)
  local node_cur = lib.get_node_at_cursor()
  local first_node_line = core.get_nodes_starting_line()
  local nodes_by_line = utils.get_nodes_by_line(core.get_explorer().nodes, first_node_line)
  local iter_start, iter_end, iter_step, cur, first, nex

  if where == "next" then
    iter_start, iter_end, iter_step = first_node_line, #nodes_by_line, 1
  elseif where == "prev" then
    iter_start, iter_end, iter_step = #nodes_by_line, first_node_line, -1
  end

  for line = iter_start, iter_end, iter_step do
    local node = nodes_by_line[line]
    local valid = false

    if what == "git" then
      local git_status = explorer_node.get_git_status(node)
      valid = git_status ~= nil and (not skip_gitignored or git_status[1] ~= "!!")
    elseif what == "diag" then
      local diag_status = diagnostics.get_diag_status(node)
      valid = diag_status ~= nil and diag_status.value ~= nil
    elseif what == "opened" then
      valid = vim.fn.bufloaded(node.absolute_path) ~= 0
    end

    if not first and valid then
      first = line
    end

    if node == node_cur then
      cur = line
    elseif valid and cur then
      nex = line
      break
    end
  end

  if nex then
    view.set_cursor { nex, 0 }
  elseif vim.o.wrapscan and first then
    view.set_cursor { first, 0 }
  end
end

---@param opts NavigationItemOpts
---@param skip_gitignored boolean default false
local function move_next_recursive(opts, skip_gitignored)
  -- If the current node:
  -- * is a directory
  -- * and has a git/diag status
  -- * and is not opened
  -- expand it.
  local node_init = lib.get_node_at_cursor()
  if not node_init then
    return
  end
  local status = get_status(node_init, opts.what)
  if node_init.nodes ~= nil and status ~= nil and not node_init.open then
    lib.expand_or_collapse(node_init)
  end

  move(opts.where, opts.what, skip_gitignored)

  local node_cur = lib.get_node_at_cursor()
  if not node_cur then
    return
  end

  -- If we haven't moved at all at this point, return.
  if node_init == node_cur then
    return
  end

  -- i is used to limit iterations.
  local i = 0
  local is_dir = node_cur.nodes ~= nil
  while is_dir and i < MAX_DEPTH do
    if not node_cur.open then
      -- Expand the node.
      -- Should never collapse since we checked open.
      lib.expand_or_collapse(node_cur)
    end

    move(opts.where, opts.what, skip_gitignored)

    -- Save current node.
    node_cur = lib.get_node_at_cursor()
    -- Update is_dir.
    if node_cur then
      is_dir = node_cur.nodes ~= nil
    else
      is_dir = false
    end

    i = i + 1
  end
end

---@class NavigationItemOpts
---@field where string
---@field what string

---@param opts NavigationItemOpts
---@return fun()
function M.fn(opts)
  return function()
    local recurse = false
    local skip_gitignored = false

    -- recurse only available for "next" git and diag moves.
    if opts.where == "next" and (opts.what == "git" or opts.what == "diag") and opts.recurse ~= nil then
      recurse = opts.recurse
    end

    if opts.skip_gitignored ~= nil then
      skip_gitignored = opts.skip_gitignored
    end

    if not recurse then
      move(opts.where, opts.what, skip_gitignored)
      return
    end

    move_next_recursive(opts, skip_gitignored)
  end
end

return M
