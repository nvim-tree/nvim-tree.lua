local Set = {}

--- Bag / Set like class to keep uniq items
--- @class Set
--- @field prototype SetInstance
--- @field prototype.constructor Set
--- @diagnostic disable-next-line: missing-fields
Set = { prototype = { constructor = Set } }
Set._mt = {
  __index = function(table, key)
    if key == "constructor" then
      return Set
    end
    return table.constructor.prototype[key] or table.constructor.super and table.constructor.super.prototype[key]
  end,
}

-- Intent: explicit dependency injection
Set.tbl_contains = vim.tbl_contains

--- Set instance
--- @class SetInstance
--- @field constructor Set Reference to a constructor
--- @field has fun(self, item: any): boolean True if has given item
--- @field set fun(self, item: any): boolean Insert item only once
--- @field del fun(self, item: any): boolean Delete item
--- @field clear fun(self): SetInstance Clear Set content

--- Creates new instance of Set class
--- @return SetInstance
function Set:new()
  local instance = {}
  instance.constructor = self
  setmetatable(instance, self._mt)
  return instance
end

--- True if has given item
function Set.prototype:has(item)
  return #self ~= 0 and self.constructor.tbl_contains(self, item)
end

--- Insert item only once
function Set.prototype:set(item)
  if not self:has(item) then
    table.insert(self, item)
    return true
  end
  return false
end

--- Delete item
function Set.prototype:del(item)
  for index, item_in in ipairs(self) do
    if item == item_in then
      table.remove(self, index)
      return true
    end
  end
  return false
end

--- Clear Set content
function Set.prototype:clear()
  for index = 1, #self do
    self[index] = nil
  end
  return self
end

return Set
