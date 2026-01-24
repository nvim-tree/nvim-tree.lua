---@meta

-- TODO #3088 document these

---@brief
---Base Node class:
---

---
---Base Node, Abstract
---
---@class nvim_tree.api.Node
---@field type "file" | "directory" | "link" uv.fs_stat.result.type
---@field absolute_path string
---@field executable boolean
---@field fs_stat? uv.fs_stat.result
---@field git_status? GitNodeStatus
---@field hidden boolean
---@field name string
---@field parent? nvim_tree.api.DirectoryNode
---@field diag_severity? lsp.DiagnosticSeverity
