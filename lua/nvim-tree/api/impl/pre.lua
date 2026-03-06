--Hydrates meta api empty definitions pre-setup:
-- - Pre-setup functions will be hydrated with their concrete implementation.
-- - Post-setup functions will notify error: "nvim-tree setup not called"
-- - All classes will be hydrated with their implementations.
--
--Called once when api is first required

local M = {}

---Walk the api, hydrating all functions with the error notification.
---Do not hydrate classes: anything with a metatable.
---@param t table
local function hydrate_error(t)
  for k, v in pairs(t) do
    if type(v) == "function" then
      t[k] = function()
        require("nvim-tree.notify").error("nvim-tree setup not called")
      end
    elseif type(v) == "table" and not getmetatable(v) then
      hydrate_error(v)
    end
  end
end

---Hydrate api functions and classes pre-setup
---@param api table not properly typed to prevent LSP from referencing implementations
function M.hydrate(api)
  -- default everything to the error message
  hydrate_error(api)

  api.Decorator             = require("nvim-tree.renderer.decorator")

  api.appearance.hi_test    = function() require("nvim-tree.appearance.hi-test")() end

  api.commands.get          = function() return require("nvim-tree.commands").get() end

  api.config.default        = function() return require("nvim-tree.config").d_clone() end

  api.events.subscribe      = function(event_name, handler) require("nvim-tree.events").subscribe(event_name, handler) end

  api.map.keymap.default    = function() return require("nvim-tree.keymap").get_keymap_default() end
  api.map.on_attach.default = function(bufnr) require("nvim-tree.keymap").on_attach_default(bufnr) end

  -- Hydrate any legacy by mapping to concrete set above
  require("nvim-tree.legacy").map_api(api)
end

return M
