---@meta
error("Cannot require a meta file")

--- Live filter allows you to filter the tree nodes dynamically, based on regex matching, see |vim.regex|
---
--- This feature is bound to the `f` key by default. The filter can be cleared with the `F` key by default.
---@class nvim_tree.Config.LiveFilter
---
---Prefix of the filter displayed in the buffer.
---(default: `[FILTER]: `)
---@field prefix? string
---
---Whether to filter folders or not.
---(default: `true`)
---@field always_show_folders? boolean
