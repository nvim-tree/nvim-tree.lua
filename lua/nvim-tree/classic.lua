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


---@brief
---
---nvim-tree uses the https://github.com/rxi/classic class framework adding safe casts, instanceof mixin and conventional destructors.
---
---The key differences between classic and ordinary Lua classes:
---- The constructor [nvim_tree.Class:new()] is not responsible for allocation: `self` is available when the constructor is called.
---- Instances are constructed via the `__call` meta method: `SomeClass(args)`
---
---Classes are conventionally named using camel case e.g. `MyClass`
---
---Classes are created by extending another class:
---```lua
---
--- local Class = require("nvim-tree.classic")
---
--- ---@class (exact) Fruit: nvim_tree.Class
--- ---@field ...
--- local Fruit = Class:extend()
---
--- ---@class (exact) Apple: Fruit
--- ---@field ...
--- local Apple = Fruit:extend()
---```
---
---Implementing a constructor [nvim_tree.Class:new()] is optional, however it must call the `super` constructor:
---```lua
---
--- ---@protected
--- ---@param args AppleArgs
--- function Apple:new(args)
---
---   ---@type FruitArgs
---   local fruit_args = ...
---
---   Apple.super.new(self, fruit_args)
---   ---
---```
---
---Create an instance of a class using the `__call` meta method that will invoke the constructor:
---```lua
---
--- ---@type AppleArgs
--- local args = ...
---
--- local an_apple = Apple(args)
--- -- above will call `Apple:new(args)`
---```
---
---In order to strongly type instantiation, the following pattern is used to type the meta method `__call` with arguments and return:
---```lua
---
--- ---@class (exact) Fruit: nvim_tree.Class
--- ---@field ...
--- local Fruit = Class:extend()
---
--- ---@class (exact) FruitArgs
--- ---@field ...
---
--- ---@class Fruit
--- ---@overload fun(args: FruitArgs): Fruit
---
--- ---@protected
--- ---@param args FruitArgs
--- function Fruit:new(args)
---```

---
---@class nvim_tree.Class
---
---Parent class, `Class` for base classes.
---@field super nvim_tree.Class
---
---mixin classes that are implemented.
---@field private implements table<nvim_tree.Class, boolean>
local Class = {}
Class.__index = Class ---@diagnostic disable-line: inject-field

---
---Constructor: `self` has been allocated and is available.
---
---Super constructor must be called using the form `Child.super.new(self, parent_args)`
---
---@param ... any constructor arguments
function Class:new(...) --luacheck: ignore 212
end

---
---Conventional destructor, optional, must be called by the owner.
---
---Parent destructor must be invoked using the form `Parent.destroy(self)`
---
function Class:destroy()
end

---
---Create a new class by extending another class.
---
---Base classes extend `Class`
---
---@return [nvim_tree.Class] child class
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

---
---Add the methods and fields of a mixin using the form `SomeClass:implement(MixinClass)`
---
---If the mixin has fields, it must implement a constructor.
---
---@param mixin nvim_tree.Class
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

---
---Instance of.
---
---Test whether an object is {class}, inherits {class} or implements mixin {class}.
---
---@generic T
---@param class T `<T>`
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

---
---Type safe cast.
---
---If instance [nvim_tree.Class:is()], cast to {class} and return it, otherwise nil.
---
---@generic T
---@param class T `<T>`
---@return T? `<T>`
function Class:as(class)
  return self:is(class) and self or nil
end

---
---Constructs an instance: calls [nvim_tree.Class:new()] and returns the new instance.
---
---@param ... any constructor args
---@return nvim_tree.Class
function Class:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end

---
---Utility method to bypass unused param warnings in abstract methods.
---
---@param ... any
function Class:nop(...) --luacheck: ignore 212
end

return Class
