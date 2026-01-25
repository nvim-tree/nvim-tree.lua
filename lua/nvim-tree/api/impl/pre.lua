--This file should have minimal requires that are cheap and have no dependencies or are already required.
--Everything must be as lazily loaded as possible: the user must be able to require api cheaply.

local commands = require("nvim-tree.commands") -- already required by plugin.lua
local events = require("nvim-tree.events")     -- needed for event registration pre-setup
local keymap = require("nvim-tree.keymap")     -- needed for default on attach
local notify = require("nvim-tree.notify")     -- already required by events and others

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
  -- Essential
  --
  api.events.Event = events.Event
  api.events.subscribe = events.subscribe

  api.map.default_on_attach = keymap.default_on_attach


  --
  -- May be lazily requried on execution
  --
  api.health.hi_test = function() require("nvim-tree.appearance.hi-test")() end


  --
  -- Already required elsewhere
  --
  api.commands.get = commands.get

  api.map.get_keymap_default = keymap.get_keymap_default


  --
  -- TODO #3241
  --
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
