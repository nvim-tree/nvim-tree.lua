---@meta
error("Cannot require a meta file")



---@alias nvim_tree.config.help.SortBy "key"|"desc"



---Configure help window, default mapping `g?`
---
---[nvim_tree.config.help.SortBy]()
---- `"key"`: alphabetically by keymap
---- `"desc"`: alphabetically by description
---
---@class nvim_tree.config.help
---
---[nvim_tree.config.help.SortBy]
---(default: `"key"`)
---@field sort_by? nvim_tree.config.help.SortBy
