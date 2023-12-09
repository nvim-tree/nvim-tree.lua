---@meta

-- TODO add "${3rd}/luv/library" to "workspace.library"
---@class uv.uv_req_t: table
---@class uv.uv_fs_t: uv.uv_req_t

---@class ParentNode
---@field name string

---@class BaseNode
---@field absolute_path string
---@field executable boolean
---@field fs_stat uv.uv_fs_t
---@field git_status GitStatus|nil
---@field hidden boolean
---@field name string
---@field parent DirNode
---@field type string
---@field watcher function|nil

---@class DirNode: BaseNode
---@field has_children boolean
---@field group_next Node|nil
---@field nodes Node[]
---@field open boolean

---@class FileNode: BaseNode
---@field extension string

---@class SymlinkDirNode: DirNode
---@field link_to string

---@class SymlinkFileNode: FileNode
---@field link_to string

---@alias SymlinkNode SymlinkDirNode|SymlinkFileNode
---@alias Node ParentNode|DirNode|FileNode|SymlinkNode|Explorer
