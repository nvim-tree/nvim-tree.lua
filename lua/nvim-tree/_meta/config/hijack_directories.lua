---@meta
error("Cannot require a meta file")



---Hijack directory buffers by replacing the directory buffer with the tree.
---
---Disable this option if you use vim-dirvish or dirbuf.nvim.
---
---If [nvim_tree.config] {hijack_netrw} and {disable_netrw} are `false` this feature will be disabled.
---
---@class nvim_tree.config.hijack_directories
---
---(default: `true`)
---@field enable? boolean
---
---Open if the tree was previously closed.
---(default: `true`)
---@field auto_open? boolean
