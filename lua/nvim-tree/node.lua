---@meta

---@class ParentNode
---@field name string

---@class BaseNode
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.fs_stat.result|nil
---@field git_status GitStatus|nil
---@field hidden boolean
---@field is_dot boolean
---@field name string
---@field parent DirNode
---@field type string
---@field watcher function|nil
---@field diag_status DiagStatus|nil

---@class DirNode: BaseNode
---@field has_children boolean
---@field group_next Node|nil
---@field nodes Node[]
---@field open boolean
---@field hidden_stats table -- Each field of this table is a key for source and value for count

---@class FileNode: BaseNode
---@field extension string

---@class SymlinkDirNode: DirNode
---@field link_to string

---@class SymlinkFileNode: FileNode
---@field link_to string

---@alias SymlinkNode SymlinkDirNode|SymlinkFileNode
---@alias Node ParentNode|DirNode|FileNode|SymlinkNode|Explorer
