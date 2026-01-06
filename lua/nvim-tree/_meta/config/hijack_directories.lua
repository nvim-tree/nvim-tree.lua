---@meta
error("Cannot require a meta file")

---@class nvim_tree.Config.HijackDirectories
---
---Hijack directory buffers. Disable this option if you use vim-dirvish or dirbuf.nvim. If `hijack_netrw` and `disable_netrw` are `false`, this feature will be disabled.
---(default: `true`)
---@field enable? boolean
---
---Opens the tree if the tree was previously closed.
---(default: `true`)
---@field auto_open? boolean
