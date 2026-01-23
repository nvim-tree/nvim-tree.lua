---@meta
local nvim_tree = { api = { fs = {} } }

nvim_tree.api.fs.copy = require("nvim-tree._meta.api.fs.copy");

---
---Clear the nvim-tree clipboard.
---
function nvim_tree.api.fs.clear_clipboard() end

---
---Prompt to create a file or directory.
---
---When {node} is a file it will be created in the parent directory.
---
---Use a trailing `"/"` to create a directory e.g. `"foo/"`
---
---Multiple directories/files may be created e.g. `"foo/bar/baz"`
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.create(node) end

---
---Cut to the nvim-tree clipboard.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.cut(node) end

---
---Paste from the nvim-tree clipboard.
---
---If {node} is a file it will pasted in the parent directory.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.paste(node) end

---
---Print the contents of the nvim-tree clipboard.
---
function nvim_tree.api.fs.print_clipboard() end

---
---Delete from the file system.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.remove(node) end

---
---Prompt to rename by name.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.rename(node) end

---
---Prompt to rename by name with extension omitted.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.rename_basename(node) end

---
---Prompt to rename by absolute path.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.rename_full(node) end

---
---Prompt to rename.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.rename_node(node) end

---
---Prompt to rename by absolute path with name omitted.
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.rename_sub(node) end

---
---Trash as per |nvim_tree.config.trash|
---
---@param node? nvim_tree.api.Node
function nvim_tree.api.fs.trash(node) end

return nvim_tree.api.fs
