---@meta
error("Cannot require a meta file")

---@alias nvim_tree.Config.Help.SortBy "key"|"desc"

---Configure help window, default mapping `g?`
---
---Valid {sort_by}:
---- `key`: sort alphabetically by keymap
---- `desc`: sort alphabetically by description
---@class nvim_tree.Config.Help
---
---(default: `key`)
---@field sort_by? nvim_tree.Config.Help.SortBy
