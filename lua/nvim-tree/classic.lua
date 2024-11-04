--
-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See LICENSE for details.
--
-- https://github.com/rxi/classic
--

---@class (exact) Object
---@field super Object
---@field private implements table<Object, boolean>
local Object = {}
Object.__index = Object ---@diagnostic disable-line: inject-field

---Default constructor
function Object:new(...)
end

---Extend a class T
---super will be set to T
---@generic T
---@param self T
---@return T
function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)
  return cls
end

---Implement the functions of a mixin
---Add the mixin to the implements table
---@param class Object
function Object:implement(class)
  if not rawget(self, "implements") then
    rawset(self, "implements", {})
  end
  self.implements[class] = true
  for k, v in pairs(class) do
    if self[k] == nil and type(v) == "function" then
      self[k] = v
    end
  end
end

---Object is an instance of class or implements a mixin
---@generic T
---@param class T
---@return boolean
function Object:is(class)
  local mt = getmetatable(self)
  while mt do
    if mt == class then
      return true
    end
    if mt.implements and mt.implements[class] then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end

---Return object if :is otherwise nil
---@generic T
---@param class T
---@return T|nil
function Object:as(class)
  return self:is(class) and self or nil
end

---Constructor that invokes :new on a new instance
---@generic T
---@param self T
---@param ... any
---@return T
function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end

-- avoid unused param warnings in abstract methods
---@param ... any
function Object:nop(...) --luacheck: ignore 212
end

return Object
