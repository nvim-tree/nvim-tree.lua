---@meta
local nvim_tree = { api = { marks = { bulk = {}, navigate = {}, } } }

---
---Return the node if it is marked.
---
---@return nvim_tree.api.Node?
function nvim_tree.api.marks.get() end

---
---Retrieve all marked nodes.
---
---@return nvim_tree.api.Node[]
function nvim_tree.api.marks.list() end

---
---Toggle mark.
---
---@param node nvim_tree.api.Node file or directory
function nvim_tree.api.marks.toggle(node) end

---
---Clear all marks.
---
function nvim_tree.api.marks.clear() end

---
---Delete all marked, prompting if [nvim_tree.config.ui.confirm] {remove}
---
function nvim_tree.api.marks.bulk.delete() end

---
---Delete all marked, prompting if [nvim_tree.config.ui.confirm] {trash}
---
function nvim_tree.api.marks.bulk.trash() end

---
---Prompts for a directory to move all marked nodes into.
---
function nvim_tree.api.marks.bulk.move() end

---
---Navigate to the next marked node, wraps.
---
function nvim_tree.api.marks.navigate.next() end

---
---Navigate to the previous marked node, wraps.
---
function nvim_tree.api.marks.navigate.prev() end

---
---Prompts for selection of a marked node, sorted by absolute paths.
---A folder will be focused, a file will be opened.
---
function nvim_tree.api.marks.navigate.select() end

return nvim_tree.api.marks
