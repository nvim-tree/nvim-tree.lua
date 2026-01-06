---@meta
error("Cannot require a meta file")

---Indicate which files have unsaved modification.
---To see modified status in the tree you will need to set:
--- - |nvim_tree.Config.Renderer.Icons.Show| {modified} to `true` OR
--- - |nvim_tree.Config.Renderer| {highlight_modified} to `true`
---@class nvim_tree.Config.Modified
---
---(default: `false`)
---@field enable? boolean
---
---Show modified indication on directory whose children are modified.
---(default: `true`)
---@field show_on_dirs? boolean
---
---Show modified indication on open directories. Only relevant when {show_on_dirs} is `true`.
---(default: `false`)
---@field show_on_open_dirs? boolean
