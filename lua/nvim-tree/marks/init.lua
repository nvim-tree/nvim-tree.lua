local renderer = {} -- circular dependency

---@class Marks
---@field private marks Node[]
local Marks = {}

---@return Marks
function Marks:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.marks = {}

  return o
end

---@private
---@param node Node
function Marks:add_mark(node)
  self.marks[node.absolute_path] = node

  renderer.draw()
end

---@private
---@param node Node
function Marks:remove_mark(node)
  self.marks[node.absolute_path] = nil

  renderer.draw()
end

---@param node Node
function Marks:toggle_mark(node)
  if node.absolute_path == nil then
    return
  end

  if self:get_mark(node) then
    self:remove_mark(node)
  else
    self:add_mark(node)
  end

  renderer.draw()
end

function Marks:clear_marks()
  self.marks = {}

  renderer.draw()
end

---@param node Node
---@return Node|nil
function Marks:get_mark(node)
  return node and self.marks[node.absolute_path]
end

---@return Node[]
function Marks:get_marks()
  local list = {}
  for _, node in pairs(self.marks) do
    table.insert(list, node)
  end
  return list
end

function Marks.setup(opts)
  renderer = require "nvim-tree.renderer"

  require("nvim-tree.marks.bulk-delete").setup(opts)
  require("nvim-tree.marks.bulk-trash").setup(opts)
  require("nvim-tree.marks.bulk-move").setup(opts)
end

return Marks
