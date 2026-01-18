---@meta
error("Cannot require a meta file")

--
-- Nodes
--


--
-- Various Types
--

---A string for rendering, with optional highlight groups to apply to it
---@class (exact) nvim_tree.api.HighlightedString
---@field str string
---@field hl string[]
