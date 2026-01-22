---@meta
local nvim_tree = { api = { node = { navigate = {}, } } }

---
---Navigate to the parent directory of the node.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.parent(node) end

---
---Navigate to the parent directory of the node, closing it.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.parent_close(node) end

nvim_tree.api.node.navigate.diagnostics = {}

---
---Navigate to the next item showing diagnostic status.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.next(node) end

---
---Navigate to the next item showing diagnostic status, recursively. Needs [nvim_tree.config.diagnostics] {show_on_dirs}
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.next_recursive(node) end

---
---Navigate to the previous item showing diagnostic status.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.prev(node) end

---
---Navigate to the previous item showing diagnostic status, recursively. Needs [nvim_tree.config.diagnostics] {show_on_dirs}
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.diagnostics.prev_recursive(node) end

nvim_tree.api.node.navigate.git = {}

---
---Navigate to the next item showing git status.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next(node) end

---
---Navigate to the next item showing git status, recursively. Needs [nvim_tree.config.git] {show_on_dirs}
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next_recursive(node) end

---
---Navigate to the next item showing git status, skipping `.gitignore`
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.next_skip_gitignored(node) end

---
---Navigate to the previous item showing git status.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev(node) end

---
---Navigate to the previous item showing git status, recursively. Needs [nvim_tree.config.git] {show_on_dirs}
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev_recursive(node) end

---
---Navigate to the previous item showing git status, skipping `.gitignore`
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.git.prev_skip_gitignored(node) end

nvim_tree.api.node.navigate.opened = {}

---
---Navigate to the next [bufloaded()] file.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.opened.next(node) end

---
---Navigate to the previous [bufloaded()] file.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.opened.prev(node) end

nvim_tree.api.node.navigate.sibling = {}

---
---Navigate to the first node in the current node's folder.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.first(node) end

---
---Navigate to the last node in the current node's folder.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.last(node) end

---
---Navigate to the next node in the current node's folder, wraps.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.next(node) end

---
---Navigate to the previous node in the current node's folder, wraps.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.navigate.sibling.prev(node) end

return nvim_tree.api.node.navigate
