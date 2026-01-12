---@meta
error("Cannot require a meta file")

---Indicate which files have unsaved modification.
---To see modified status in the tree you will need:
--- - [nvim_tree.Config.Renderer.Icons.Show] {modified} OR
--- - [nvim_tree.Config.Renderer] {highlight_modified}
---@class nvim_tree.Config.Modified
---
---(default: `false`)
---@field enable? boolean
---
---Show modified indication on directory whose children are modified.
---(default: `true`)
---@field show_on_dirs? boolean
---
---Show modified indication on open directories. Requires {show_on_dirs}.
---(default: `false`)
---@field show_on_open_dirs? boolean
