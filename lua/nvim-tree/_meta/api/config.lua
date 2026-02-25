---@meta
local nvim_tree = { api = { config = {} } }

---
---Default nvim-tree config.
---
---@return nvim_tree.config immutable deep clone
function nvim_tree.api.config.default() end

---
---Global current nvim-tree config.
---
---@return nvim_tree.config immutable deep clone
function nvim_tree.api.config.global() end

---
---Reference to config passed to [nvim-tree-setup]
---
---@return nvim_tree.config? nil when no config passed to setup
function nvim_tree.api.config.user() end

nvim_tree.api.config.mappings = {}

---@deprecated use `nvim_tree.api.map.keymap.current()`
function nvim_tree.api.config.mappings.get_keymap() end

---@deprecated use `nvim_tree.api.map.keymap.default()`
function nvim_tree.api.config.mappings.get_keymap_default() end

---@deprecated use `nvim_tree.api.map.on_attach.default()`
function nvim_tree.api.config.mappings.default_on_attach(bufnr) end

return nvim_tree.api.config
