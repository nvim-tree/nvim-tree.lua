local events = require("nvim-tree.events")
local keymap = require("nvim-tree.keymap")
local notify = require("nvim-tree.notify")

local UserDecorator = require("nvim-tree.renderer.decorator.user")

---Walk the api, hydrating all functions with the error notification
---@param t table api root or sub-module
local function hydrate_notify(t)
  for k, v in pairs(t) do
    if type(v) == "function" then
      t[k] = function()
        notify.error("nvim-tree setup not called")
      end
    elseif type(v) == "table" then
      hydrate_notify(v)
    end
  end
end

---Hydrate implementations that may be called pre setup
---@param api table
local function hydrate_pre(api)
  api.events.subscribe = events.subscribe
  api.events.Event = events.Event

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
--
--Call it once when api is first required
--
--This should not include any requires beyond that which is absolutely essential,
--as the user should be able to require api cheaply.
---@param api table
return function(api)
  -- Default: error
  hydrate_notify(api)

  -- Exceptions: may be called
  hydrate_pre(api)

  -- Hydrate any legacy by mapping to function set above
  require("nvim-tree.legacy").map_api(api)
end
