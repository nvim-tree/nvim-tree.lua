---@meta
error("Cannot require a meta file")

---nvim-tree notifications levels:
---- ERROR: hard errors e.g. failure to read from the file system.
---- WARN: non-fatal errors e.g. unable to system open a file.
---- INFO: information only e.g. file copy path confirmation.
---- DEBUG: information for troubleshooting, e.g. failures in some window closing operations.
---
---@class nvim_tree.Config.Notify
---
---Specify minimum notification level
---(Default: `vim.log.levels.INFO`)
---@field threshold? vim.log.levels
---
---Use absolute paths in FS action notifications, otherwise item names.
---(default: `true`)
---@field absolute_path? boolean
