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

---TODO #3241 document and rename
---@class Class: nvim_tree.Class
---@nodoc

---@class nvim_tree.Class
---@field super Class
---@field private implements table<Class, boolean>
local Class = {}
Class.__index = Class ---@diagnostic disable-line: inject-field

---Default constructor
function Class:new(...) --luacheck: ignore 212
end

---Extend a class, setting .super
function Class:extend()
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
---Add the mixin to .implements
---@param mixin Class
function Class:implement(mixin)
  if not rawget(self, "implements") then
    -- set on the class itself instead of parents
    rawset(self, "implements", {})
  end
  self.implements[mixin] = true
  for k, v in pairs(mixin) do
    if self[k] == nil and type(v) == "function" then
      self[k] = v
    end
  end
end

---Object is an instance of class or implements a mixin
---@generic T
---@param class T
---@return boolean
function Class:is(class)
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

---Return object if [nvim_tree.Class:is()] otherwise nil
---@generic T
---@param class T
---@return T|nil
function Class:as(class)
  return self:is(class) and self or nil
end

---Constructor to create instance, call [nvim_tree.Class:new()] and return
function Class:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end

-- avoid unused param warnings in abstract methods
---@param ... any
function Class:nop(...) --luacheck: ignore 212
end

return Class
