---@meta
local nvim_tree = { api = { events = {} } }

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
---@param event_type string [nvim_tree_events_kind]
---@param callback fun(payload: table?)
function nvim_tree.api.events.subscribe(event_type, callback) end

return nvim_tree.api.events
