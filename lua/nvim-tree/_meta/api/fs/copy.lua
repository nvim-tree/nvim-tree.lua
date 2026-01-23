---@meta
local nvim_tree = { api = { fs = { copy = {} } } }

---
---Copy the absolute path to the system clipboard.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.copy.absolute_path(node) end

---
---Copy the name with extension omitted to the system clipboard.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.copy.basename(node) end

---
---Copy the name to the system clipboard.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.copy.filename(node) end

---
---Copy to the nvim-tree clipboard.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.copy.node(node) end

---
---Copy the path relative to the tree root to the system clipboard.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.copy.relative_path(node) end

return nvim_tree.api.fs.copy
