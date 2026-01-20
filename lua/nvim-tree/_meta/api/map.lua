---@meta
local nvim_tree = { api = { map = {} } }

---
---Retrieve all buffer local mappings for nvim-tree. These are the mappings that are applied by [nvim_tree.Config] {on_attach}, which may include default mappings.
---
---@return vim.api.keyset.get_keymap[]
function nvim_tree.api.map.get_keymap() end

---
--- Retrieves the buffer local mappings for nvim-tree that are applied by [nvim_tree.api.map.default_on_attach()]
---
---@return vim.api.keyset.get_keymap[]
function nvim_tree.api.map.get_keymap_default() end

---
---Apply all [nvim-tree-mappings-default]. Call from your [nvim_tree.Config] {on_attach}.
---
---@param bufnr integer use the `bufnr` passed to {on_attach}
function nvim_tree.api.map.default_on_attach(bufnr) end

require("nvim-tree.api-impl").map(nvim_tree.api.map)

return nvim_tree.api.map
