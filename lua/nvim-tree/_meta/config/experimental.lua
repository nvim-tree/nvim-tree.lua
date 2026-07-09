---@meta
error("Cannot require a meta file")



---Experimental features that may become default or optional functionality.
---
---In the event of a problem please disable the experiment and raise an issue.
---
---@class nvim_tree.config.experimental
---
---Restore nvim-tree buffers when restoring vim sessions (requires 0.13+).
---(default: `false`)
---@field session_restore_nvim? boolean
--Example below for future reference:
--
--Buffers opened by nvim-tree will use with relative paths instead of absolute.
--(default: false)
--@field relative_path? boolean
