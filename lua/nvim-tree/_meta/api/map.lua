---@meta
local nvim_tree = { api = { map = {} } }

nvim_tree.api.map.keymap = {}

---
---Retrieve all buffer local mappings for nvim-tree. These are the mappings that are applied by [nvim_tree.config] {on_attach}, which may include default mappings.
---
---@return vim.api.keyset.get_keymap[]
function nvim_tree.api.map.keymap.current() end

---
--- Retrieves the buffer local mappings for nvim-tree that are applied by [nvim_tree.api.map.on_attach.default()]
---
---@return vim.api.keyset.get_keymap[]
function nvim_tree.api.map.keymap.default() end

nvim_tree.api.map.on_attach = {}

---
---Apply all [nvim-tree-mappings-default]. Call from your [nvim_tree.config] {on_attach}.
---
---@param bufnr integer use the `bufnr` passed to {on_attach}
function nvim_tree.api.map.on_attach.default(bufnr) end

return nvim_tree.api.map
