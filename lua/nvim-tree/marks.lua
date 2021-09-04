local lib = require'nvim-tree.lib'
local view = require'nvim-tree.view'
local renderer = require'nvim-tree.renderer'

local M = {}

local function iterate_get_marks(node)
  local marks = {}
  for _, n in pairs(node.entries) do
    if n.marked then
      table.insert(marks, n)
    end
    if n.entries then
      vim.fn.extend(marks, iterate_get_marks(n))
    end
  end
  return marks
end

function M.get_marks()
  return iterate_get_marks(lib.Tree)
end

function M.toggle_mark()
  local node = lib.get_node_at_cursor()
  if not node then
    return
  end

  node.marked = not node.marked
  if view.win_open() then
    renderer.draw(lib.Tree, true)
  end
end

local function iterate_toggle_off(node)
  for _, n in pairs(node.entries) do
    n.marked = false
    if n.entries then
      iterate_toggle_off(n)
    end
  end
end

function M.disable_all()
  iterate_toggle_off(lib.Tree)
  if view.win_open() then
    renderer.draw(lib.Tree, true)
  end
end

return M
