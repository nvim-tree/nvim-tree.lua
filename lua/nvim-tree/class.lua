---Generic class, useful for inheritence.
---@class (exact) Class
local Class = {}

---@generic T
---@param self T
---@param o T|nil
---@return T
function Class:new(o)
  o = o or {}

  setmetatable(o, self)
  self.__index = self ---@diagnostic disable-line: inject-field

  return o
end

---Object is an instance of class
---This will start with the lowest class and loop over all the superclasses.
---@generic T
---@param class T
---@return boolean
function Class:is(class)
  local mt = getmetatable(self)
  while mt do
    if mt == class then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end

---Return object if it is an instance of class, otherwise nil
---@generic T
---@param class T
---@return T|nil
function Class:as(class)
  return self:is(class) and self or nil
end

-- avoid unused param warnings in abstract methods
---@param ... any
function Class:nop(...) --luacheck: ignore 212
end

return Class
