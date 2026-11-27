---@meta
local nvim_tree = { api = { events = {} } }

---@enum nvim_tree.api.events.Event
nvim_tree.api.events.Event = {
  Ready = "Ready",
  WillRenameNode = "WillRenameNode",
  NodeRenamed = "NodeRenamed",
  TreePreOpen = "TreePreOpen",
  TreeOpen = "TreeOpen",
  TreeClose = "TreeClose",
  WillCreateFile = "WillCreateFile",
  FileCreated = "FileCreated",
  WillRemoveFile = "WillRemoveFile",
  FileRemoved = "FileRemoved",
  FolderCreated = "FolderCreated",
  FolderRemoved = "FolderRemoved",
  Resize = "Resize",
  TreeAttachedPost = "TreeAttachedPost",
  TreeRendered = "TreeRendered",
}

---
---Register a handler for an event, see [nvim-tree-events].
---
---@param event_type nvim_tree.api.events.Event [nvim_tree_events_kind]
---@param callback fun(payload: table)
---@overload fun(event_type: "Ready", callback: fun())
---@overload fun(event_type: "TreePreOpen", callback: fun())
---@overload fun(event_type: "TreeOpen", callback: fun())
---@overload fun(event_type: "TreeClose", callback: fun())
---@overload fun(event_type: "Resize", callback: fun(size: number))
---@overload fun(event_type: "WillRenameNode", callback: fun(payload: {old_name: string, new_name: string}))
---@overload fun(event_type: "NodeRenamed", callback: fun(payload: {old_name: string, new_name: string}))
---@overload fun(event_type: "WillCreateFile", callback: fun(payload: {fname: string}))
---@overload fun(event_type: "FileCreated", callback: fun(payload: {fname: string}))
---@overload fun(event_type: "WillRemoveFile", callback: fun(payload: {fname: string}))
---@overload fun(event_type: "FileRemoved", callback: fun(payload: {fname: string}))
---@overload fun(event_type: "FolderCreated", callback: fun(payload: {folder_name: string}))
---@overload fun(event_type: "FolderRemoved", callback: fun(payload: {folder_name: string}))
---@overload fun(event_type: "TreeAttachedPost", callback: fun(buf: integer))
---@overload fun(event_type: "TreeRendered", callback: fun(payload: {bufnr: integer, winnr: integer}))
function nvim_tree.api.events.subscribe(event_type, callback) end

return nvim_tree.api.events
