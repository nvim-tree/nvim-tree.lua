---@meta
error("Cannot require a meta file")


---Configure help window, default mapping `g?`
---
---@alias nvim_tree.Config.Help.SortBy "key"|"desc"
---[nvim_tree.Config.Help.SortBy]()
---- `key`: alphabetically by keymap
---- `desc`: alphabetically by description
---
---@class nvim_tree.Config.Help
---
---[nvim_tree.Config.Help.SortBy]
---(default: `key`)
---@field sort_by? nvim_tree.Config.Help.SortBy
