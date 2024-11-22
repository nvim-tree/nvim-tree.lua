---@meta

---Highlight group range as per nvim-tree.renderer.highlight_*
---@alias DecoratorHighlightRange "none" | "icon" | "name" | "all"

---Icon position as per renderer.icons.*_placement
---@alias DecoratorIconPlacement "none" | "before" | "after" | "signcolumn" | "right_align"

---Decorator Constructor Arguments
---@class (exact) DecoratorArgs
---@field enabled boolean
---@field highlight_range DecoratorHighlightRange
---@field icon_placement DecoratorIconPlacement

---A string for rendering, with optional highlight groups to apply to it
---@class (exact) HighlightedString
---@field str string
---@field hl string[]
