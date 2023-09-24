local renderer = {} -- circular dependency

local NvimTreeMarks = {}

local M = {}

local function add_mark(node)
  NvimTreeMarks[node.absolute_path] = node

  renderer.draw()
end

local function remove_mark(node)
  NvimTreeMarks[node.absolute_path] = nil

  renderer.draw()
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

  renderer.draw()
end

function M.clear_marks()
  NvimTreeMarks = {}

  renderer.draw()
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
  renderer = require "nvim-tree.renderer"

  require("nvim-tree.marks.bulk-delete").setup(opts)
  require("nvim-tree.marks.bulk-trash").setup(opts)
  require("nvim-tree.marks.bulk-move").setup(opts)
end

return M
