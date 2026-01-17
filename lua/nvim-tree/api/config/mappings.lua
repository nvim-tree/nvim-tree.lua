---@meta


-- # TODO #3088 this should be api/config.lua however that results in a filename clash in gen_vimdoc_config.lua


local nvim_tree = { api = { config = { mappings = {} } } }



---Retrieve all buffer local mappings for nvim-tree. These are the mappings that are applied by [nvim_tree.Config] {on_attach}, which may include default mappings.
---
---@return vim.api.keyset.get_keymap[]
function nvim_tree.api.config.mappings.get_keymap() end



--- Retrieves the buffer local mappings for nvim-tree that are applied by [nvim_tree.api.config.mappings.default_on_attach()]
---
---@return vim.api.keyset.get_keymap[]
function nvim_tree.api.config.mappings.get_keymap_default() end



---Apply all [nvim-tree-mappings-default]. Call from your [nvim_tree.Config] {on_attach}.
---
---@param bufnr integer use the `bufnr` passed to {on_attach}
function nvim_tree.api.config.mappings.default_on_attach(bufnr) end



require("nvim-tree.api").hydrate_config(nvim_tree.api.config)

return nvim_tree.api.tree
