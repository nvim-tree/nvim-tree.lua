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
---@param skip_gitignored boolean default false
---@return boolean
local function status_is_valid(node, what, skip_gitignored)
  if what == "git" then
    local git_status = explorer_node.get_git_status(node)
    return git_status ~= nil and (not skip_gitignored or git_status[1] ~= "!!")
  elseif what == "diag" then
    local diag_status = diagnostics.get_diag_status(node)
    return diag_status ~= nil and diag_status.value ~= nil
  elseif what == "opened" then
    return vim.fn.bufloaded(node.absolute_path) ~= 0
  end

  return false
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
    local valid = status_is_valid(node, what, skip_gitignored)

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

local function expand_node(node)
  if not node.open then
    -- Expand the node.
    -- Should never collapse since we checked open.
    lib.expand_or_collapse(node)
  end
end

--- Move to the next node recursively.
---@param what string type of status
---@param skip_gitignored boolean default false
local function move_next_recursive(what, skip_gitignored)
  -- If the current node:
  -- * is a directory
  -- * and is not the root node
  -- * and has a git/diag status
  -- * and is not opened
  -- expand it.
  local node_init = lib.get_node_at_cursor()
  if not node_init then
    return
  end
  local valid = false
  if node_init.name ~= ".." then -- root node cannot have a status
    valid = status_is_valid(node_init, what, skip_gitignored)
  end
  if node_init.nodes ~= nil and valid and not node_init.open then
    lib.expand_or_collapse(node_init)
  end

  move("next", what, skip_gitignored)

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
    expand_node(node_cur)

    move("next", what, skip_gitignored)

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

--- Move to the previous node recursively.
---
--- move_prev_recursive:
---
--- 1) Save current as node_init.
--  2) Call a non-recursive prev.
--- 3) If current node is node_init's parent, call move_prev_recursive.
--- 4) Else:
--- 4.1) If current node is nil, is node_init (we didn't move), or is a file, return.
--- 4.2) The current file is a directory, expand it.
--- 4.3) Find node_init in current window, and move to it (if not found, return).
---      If node_init is the root node (name = ".."), directly move to position 1.
--- 4.4) Call a non-recursive prev.
--- 4.5) Save the current node and start back from 4.1.
---
---@param what string type of status
---@param skip_gitignored boolean default false
local function move_prev_recursive(what, skip_gitignored)
  local node_init, node_cur

  -- 1)
  node_init = lib.get_node_at_cursor()
  if node_init == nil then
    return
  end

  -- 2)
  move("prev", what, skip_gitignored)

  node_cur = lib.get_node_at_cursor()
  if node_cur == node_init.parent then
    -- 3)
    move_prev_recursive(what, skip_gitignored)
  else
    -- i is used to limit iterations.
    local i = 0
    while i < MAX_DEPTH do
      -- 4.1)
      if
        node_cur == nil
        or node_cur == node_init -- we didn't move
        or not node_cur.nodes -- node is a file
      then
        return
      end

      -- 4.2)
      local node_dir = node_cur
      expand_node(node_dir)

      -- 4.3)
      if node_init.name == ".." then -- root node
        view.set_cursor { 1, 0 } -- move to root node (position 1)
      else
        local node_init_line = utils.find_node_line(node_init)
        if node_init_line < 0 then
          return
        end
        view.set_cursor { node_init_line, 0 }
      end

      -- 4.4)
      move("prev", what, skip_gitignored)

      -- 4.5)
      node_cur = lib.get_node_at_cursor()

      i = i + 1
    end
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

    -- recurse only valid for git and diag moves.
    if (opts.what == "git" or opts.what == "diag") and opts.recurse ~= nil then
      recurse = opts.recurse
    end

    if opts.skip_gitignored ~= nil then
      skip_gitignored = opts.skip_gitignored
    end

    if not recurse then
      move(opts.where, opts.what, skip_gitignored)
      return
    end

    if opts.where == "next" then
      move_next_recursive(opts.what, skip_gitignored)
    elseif opts.where == "prev" then
      move_prev_recursive(opts.what, skip_gitignored)
    end
  end
end

return M
