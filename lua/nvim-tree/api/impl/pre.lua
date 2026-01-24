--This file should have no requires barring the essentials.
--Everything must be as lazily loaded as possible.
--The user must be able to require api cheaply and run setup cheaply.
local events = require("nvim-tree.events")
local keymap = require("nvim-tree.keymap")
local notify = require("nvim-tree.notify")

local UserDecorator = require("nvim-tree.renderer.decorator.user")

---Walk the api, hydrating all functions with the error notification
---@param t table api root or sub-module
local function hydrate_error(t)
  for k, v in pairs(t) do
    if type(v) == "function" then
      t[k] = function()
        notify.error("nvim-tree setup not called")
      end
    elseif type(v) == "table" then
      hydrate_error(v)
    end
  end
end

---Hydrate implementations that may be called pre setup
---@param api table
local function hydrate_pre(api)
  --
  -- May be lazily requried on execution
  --
  api.commands.get = function() require("nvim-tree.commands").get() end

  api.health.hi_test = function() require("nvim-tree.appearance.hi-test")() end

  --
  -- Must be eagerly required or common
  --
  api.events.Event = events.Event
  api.events.subscribe = events.subscribe

  api.map.default_on_attach = keymap.default_on_attach

  api.decorator = {}
  ---Create a decorator class by calling :extend()
  ---See :help nvim-tree-decorators
  ---@type nvim_tree.api.decorator.UserDecorator
  api.decorator.UserDecorator = UserDecorator --[[@as nvim_tree.api.decorator.UserDecorator]]
end

--Hydrates meta api empty definition functions with a new function:
-- - Default: error notification "nvim-tree setup not called".
-- - Exceptions: concrete implementation for API that can be called before setup.
--Call it once when api is first required
---@param api table
return function(api)
  -- Default: error
  hydrate_error(api)

  -- Exceptions: may be called
  hydrate_pre(api)

  -- Hydrate any legacy by mapping to function set above
  require("nvim-tree.legacy").map_api(api)
end
