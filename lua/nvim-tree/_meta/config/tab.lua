---@meta
error("Cannot require a meta file")



---@class nvim_tree.config.tab
---
---[nvim_tree.config.tab.sync]
---@field sync? nvim_tree.config.tab.sync



---@class nvim_tree.config.tab.sync
---
---Opens the tree automatically when switching tabpage or opening a new tabpage if the tree was previously open.
---(default: `false`)
---@field open? boolean
---
---Closes the tree across all tabpages when the tree is closed.
---(default: `false`)
---@field close? boolean
---
---
---List of filetypes or buffer names on new tab that will prevent `open` and `close`
---(default: `{}`)
---@field ignore? string[]
