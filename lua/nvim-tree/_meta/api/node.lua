---@meta
local nvim_tree = { api = { node = {} } }

nvim_tree.api.node.navigate = require("nvim-tree._meta.api.node.navigate");
nvim_tree.api.node.open = require("nvim-tree._meta.api.node.open");

---
---@class nvim_tree.api.node.buffer.RemoveOpts
---@inlinedoc
---
---Proceed even if the buffer is modified.
---(default: false)
---@field force? boolean


nvim_tree.api.node.buffer = {}

---
---Deletes node's related buffer, if one exists. Executes [:bdelete] or [:bdelete]!
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.buffer.RemoveOpts
function nvim_tree.api.node.buffer.delete(node, opts) end

---
---Wipes node's related buffer, if one exists. Executes [:bwipe] or [:bwipe]!
---
---@param node? nvim_tree.api.Node file
---@param opts? nvim_tree.api.node.buffer.RemoveOpts optional
function nvim_tree.api.node.buffer.wipe(node, opts) end

---
---Collapse the tree under a directory or a file's parent directory.
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.collapse.Opts optional
function nvim_tree.api.node.collapse(node, opts) end

---@class nvim_tree.api.node.collapse.Opts
---@inlinedoc
---
---Do not collapse nodes with open buffers.
---(default: false)
---@field keep_buffers? boolean

---
---Recursively expand all nodes under a directory or a file's parent directory.
---
---@param node? nvim_tree.api.Node directory or file
---@param opts? nvim_tree.api.node.expand.Opts optional
function nvim_tree.api.node.expand(node, opts) end

---@class nvim_tree.api.node.expand.Opts
---@inlinedoc
---
---Return `true` if `node` should be expanded. `expansion_count` is the total number of folders expanded.
---@field expand_until? fun(expansion_count: integer, node: Node): boolean


nvim_tree.api.node.run = {}

---
---Enter [cmdline] with the full path of the node and the cursor at the start of the line.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.run.cmd(node) end

---
---Execute [nvim_tree.config.system_open].
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.run.system(node) end

---
---Open a popup window showing: fullpath, size, accessed, modified, created.
---
---@param node? nvim_tree.api.Node directory or file
function nvim_tree.api.node.show_info_popup(node) end

return nvim_tree.api.node
