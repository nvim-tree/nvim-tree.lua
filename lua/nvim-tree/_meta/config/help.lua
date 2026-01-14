---@meta
error("Cannot require a meta file")



---@alias nvim_tree.Config.Help.SortBy "key"|"desc"



---@brief
---Configure help window, default mapping `g?`
---
---[nvim_tree.Config.Help.SortBy]()
---- `"key"`: alphabetically by keymap
---- `"desc"`: alphabetically by description



---@class nvim_tree.Config.Help
---
---[nvim_tree.Config.Help.SortBy]
---(default: `"key"`)
---@field sort_by? nvim_tree.Config.Help.SortBy
