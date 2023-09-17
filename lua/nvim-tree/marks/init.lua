local NvimTreeMarks = {}

local M = {}

local function add_mark(node)
  NvimTreeMarks[node.absolute_path] = node

  require("nvim-tree.renderer").draw()
end

local function remove_mark(node)
  NvimTreeMarks[node.absolute_path] = nil

  require("nvim-tree.renderer").draw()
end

function M.toggle_mark(node)
  if node.absolute_path == nil then
    return
  end

  if M.get_mark(node) then
    remove_mark(node)
  else
    add_mark(node)
  end

  require("nvim-tree.renderer").draw()
end

function M.clear_marks()
  NvimTreeMarks = {}

  require("nvim-tree.renderer").draw()
end

function M.get_mark(node)
  return NvimTreeMarks[node.absolute_path]
end

function M.get_marks()
  local list = {}
  for _, node in pairs(NvimTreeMarks) do
    table.insert(list, node)
  end
  return list
end

function M.setup(opts)
  require("nvim-tree.marks.bulk-delete").setup(opts)
  require("nvim-tree.marks.bulk-trash").setup(opts)
  require("nvim-tree.marks.bulk-move").setup(opts)
end

return M
