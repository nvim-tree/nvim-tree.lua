---@meta
error("Cannot require a meta file")



---@brief
---Files may be trashed via an external command that must be installed on your system.
--- - linux: `gio trash`, from linux package `glib2`
--- - macOS: `trash`, from homebrew package `trash`
--- - windows: `trash`, requires `trash-cli` or similar



---@class nvim_tree.Config.Trash
---
---External command.
---(default: `gio trash` or `trash`)
---@field cmd? string
