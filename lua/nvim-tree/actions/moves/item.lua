local view = require("nvim-tree.view")
local core = require("nvim-tree.core")
local diagnostics = require("nvim-tree.diagnostics")

local FileNode = require("nvim-tree.node.file")
local DirectoryNode = require("nvim-tree.node.directory")

local M = {}
local MAX_DEPTH = 100

---Return the status of the node or nil if no status, depending on the type of
---status.
---@param node Node to inspect
---@param what string? type of status
---@param skip_gitignored boolean? default false
---@return boolean
local function status_is_valid(node, what, skip_gitignored)
  if what == "git" then
    local git_xy = node:get_git_xy()
    return git_xy ~= nil and (not skip_gitignored or git_xy[1] ~= "!!")
  elseif what == "diag" then
    local diag_status = diagnostics.get_diag_status(node)
    return diag_status ~= nil and diag_status.value ~= nil
  elseif what == "opened" then
    return vim.fn.bufloaded(node.absolute_path) ~= 0
  end

  return false
end

---Move to the next node that has a valid status. If none found, don't move.
---@param explorer Explorer
---@param where string? where to move (forwards or backwards)
---@param what string? type of status
---@param skip_gitignored boolean? default false
local function move(explorer, where, what, skip_gitignored)
  local first_node_line = core.get_nodes_starting_line()
  local nodes_by_line = explorer:get_nodes_by_line(first_node_line)
  local iter_start, iter_end, iter_step, cur, first, nex

  local cursor = explorer:get_cursor_position()
  if cursor and cursor[1] < first_node_line then
    cur = cursor[1]
  end

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

    if cursor and line == cursor[1] then
      cur = line
    elseif valid and cur then
      nex = line
      break
    end
  end

  if nex then
    view.set_cursor({ nex, 0 })
  elseif vim.o.wrapscan and first then
    view.set_cursor({ first, 0 })
  end
end

---@param node DirectoryNode
local function expand_node(node)
  if not node.open then
    -- Expand the node.
    -- Should never collapse since we checked open.
    node:expand_or_collapse(false)
  end
end

--- Move to the next node recursively.
---@param explorer Explorer
---@param what string? type of status
---@param skip_gitignored? boolean default false
local function move_next_recursive(explorer, what, skip_gitignored)
  -- If the current node:
  -- * is a directory
  -- * and is not the root node
  -- * and has a git/diag status
  -- * and is not opened
  -- expand it.
  local node_init = explorer:get_node_at_cursor()
  if not node_init then
    return
  end
  local valid = false
  if node_init.name ~= ".." then -- root node cannot have a status
    valid = status_is_valid(node_init, what, skip_gitignored)
  end
  local node_dir = node_init:as(DirectoryNode)
  if node_dir and valid and not node_dir.open then
    node_dir:expand_or_collapse(false)
  end

  move(explorer, "next", what, skip_gitignored)

  local node_cur = explorer:get_node_at_cursor()
  if not node_cur then
    return
  end

  -- If we haven't moved at all at this point, return.
  if node_init == node_cur then
    return
  end

  -- i is used to limit iterations.
  local i = 0
  local dir_cur = node_cur:as(DirectoryNode)
  while dir_cur and i < MAX_DEPTH do
    expand_node(dir_cur)

    move(explorer, "next", what, skip_gitignored)

    -- Save current node.
    node_cur = explorer:get_node_at_cursor()
    dir_cur = node_cur and node_cur:as(DirectoryNode)

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
---@param explorer Explorer
---@param what string? type of status
---@param skip_gitignored boolean? default false
local function move_prev_recursive(explorer, what, skip_gitignored)
  local node_init, node_cur

  -- 1)
  node_init = explorer:get_node_at_cursor()
  if node_init == nil then
    return
  end

  -- 2)
  move(explorer, "prev", what, skip_gitignored)

  node_cur = explorer:get_node_at_cursor()
  if node_cur == node_init.parent then
    -- 3)
    move_prev_recursive(explorer, what, skip_gitignored)
  else
    -- i is used to limit iterations.
    local i = 0
    while i < MAX_DEPTH do
      -- 4.1)
      if
        node_cur == nil
        or node_cur == node_init -- we didn't move
        or node_cur:is(FileNode) -- node is a file
      then
        return
      end

      -- 4.2)
      local node_dir = node_cur:as(DirectoryNode)
      if node_dir then
        expand_node(node_dir)
      end

      -- 4.3)
      if node_init.name == ".." then -- root node
        view.set_cursor({ 1, 0 })    -- move to root node (position 1)
      else
        local node_init_line = explorer:find_node_line(node_init)
        if node_init_line < 0 then
          return
        end
        view.set_cursor({ node_init_line, 0 })
      end

      -- 4.4)
      move(explorer, "prev", what, skip_gitignored)

      -- 4.5)
      node_cur = explorer:get_node_at_cursor()

      i = i + 1
    end
  end
end

---@class NavigationItemOpts
---@field where string?
---@field what string?
---@field skip_gitignored boolean?
---@field recurse boolean?

---@param opts NavigationItemOpts
local function item(opts)
  local explorer = core.get_explorer()
  if not explorer then
    return
  end

  local recurse = false

  -- recurse only valid for git and diag moves.
  if (opts.what == "git" or opts.what == "diag") and opts.recurse ~= nil then
    recurse = opts.recurse
  end

  if not recurse then
    move(explorer, opts.where, opts.what, opts.skip_gitignored)
    return
  end

  if opts.where == "next" then
    move_next_recursive(explorer, opts.what, opts.skip_gitignored)
  elseif opts.where == "prev" then
    move_prev_recursive(explorer, opts.what, opts.skip_gitignored)
  end
end

function M.git_next()
  item({ where = "next", what = "git" })
end

function M.git_next_skip_gitignored()
  item({ where = "next", what = "git", skip_gitignored = true })
end

function M.git_next_recursive()
  item({ where = "next", what = "git", recurse = true })
end

function M.git_prev()
  item({ where = "prev", what = "git" })
end

function M.git_prev_skip_gitignored()
  item({ where = "prev", what = "git", skip_gitignored = true })
end

function M.git_prev_recursive()
  item({ where = "prev", what = "git", recurse = true })
end

function M.diagnostics_next()
  item({ where = "next", what = "diag" })
end

function M.diagnostics_next_recursive()
  item({ where = "next", what = "diag", recurse = true })
end

function M.diagnostics_prev()
  item({ where = "prev", what = "diag" })
end

function M.diagnostics_prev_recursive()
  item({ where = "prev", what = "diag", recurse = true })
end

function M.opened_next()
  item({ where = "next", what = "opened" })
end

function M.opened_prev()
  item({ where = "prev", what = "opened" })
end

return M
