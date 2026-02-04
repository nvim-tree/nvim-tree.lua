---@meta
-- Deprecated top level API modules.
-- Remember to add mappings in legacy.lua `api_map`

local nvim_tree = { api = {} }

nvim_tree.api.config = {}

nvim_tree.api.config.mappings = {}

---@deprecated use `nvim_tree.api.map.keymap.current()`
function nvim_tree.api.config.mappings.get_keymap() end

---@deprecated use `nvim_tree.api.map.keymap.default()`
function nvim_tree.api.config.mappings.get_keymap_default() end

---@deprecated use `nvim_tree.api.map.on_attach.default()`
function nvim_tree.api.config.mappings.default_on_attach(bufnr) end

nvim_tree.api.live_filter = {}

---@deprecated use `nvim_tree.api.filter.live.start()`
function nvim_tree.api.live_filter.start() end

---@deprecated use `nvim_tree.api.filter.live.clear()`
function nvim_tree.api.live_filter.clear() end

nvim_tree.api.diagnostics = {}

---@deprecated use `nvim_tree.api.health.hi_test()`
function nvim_tree.api.diagnostics.hi_test() end

nvim_tree.api.decorator = {}

---@class nvim_tree.api.decorator.UserDecorator: nvim_tree.api.Decorator
---@deprecated use `nvim_tree.api.Decorator`
nvim_tree.api.decorator.UserDecorator = nvim_tree.api.Decorator

return nvim_tree.api
