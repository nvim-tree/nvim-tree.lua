---@meta

-- Deprecated top level API modules.
-- Remember to add mappings in legacy.lua `api_map`

local M = {}

M.config = {}

M.config.mappings = {}

---@deprecated use `nvim_tree.api.map.keymap.current()`
function M.config.mappings.get_keymap() end

---@deprecated use `nvim_tree.api.map.keymap.default()`
function M.config.mappings.get_keymap_default() end

---@deprecated use `nvim_tree.api.map.on_attach.default()`
function M.config.mappings.default_on_attach(bufnr) end

M.live_filter = {}

---@deprecated use `nvim_tree.api.filter.live.start()`
function M.live_filter.start() end

---@deprecated use `nvim_tree.api.filter.live.clear()`
function M.live_filter.clear() end

M.diagnostics = {}

---@deprecated use `nvim_tree.api.health.hi_test()`
function M.diagnostics.hi_test() end

return M
