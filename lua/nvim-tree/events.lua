local notify = require("nvim-tree.notify")

local M = {}

local global_handlers = {}

M.Event = {
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

---@param event_name string
---@return table
local function get_handlers(event_name)
  return global_handlers[event_name] or {}
end

---@param event_name string
---@param handler function
function M.subscribe(event_name, handler)
  local handlers = get_handlers(event_name)
  table.insert(handlers, handler)
  global_handlers[event_name] = handlers
end

---@param event_name string
---@param payload table|nil
local function dispatch(event_name, payload)
  for _, handler in pairs(get_handlers(event_name)) do
    local success, error = pcall(handler, payload)
    if not success then
      notify.error("Handler for event " .. event_name .. " errored. " .. vim.inspect(error))
    end
  end
end

--@private
function M._dispatch_ready()
  dispatch(M.Event.Ready)
end

--@private
function M._dispatch_will_rename_node(old_name, new_name)
  dispatch(M.Event.WillRenameNode, { old_name = old_name, new_name = new_name })
end

--@private
function M._dispatch_node_renamed(old_name, new_name)
  dispatch(M.Event.NodeRenamed, { old_name = old_name, new_name = new_name })
end

--@private
function M._dispatch_will_remove_file(fname)
  dispatch(M.Event.WillRemoveFile, { fname = fname })
end

--@private
function M._dispatch_file_removed(fname)
  dispatch(M.Event.FileRemoved, { fname = fname })
end

--@private
function M._dispatch_will_create_file(fname)
  dispatch(M.Event.WillCreateFile, { fname = fname })
end

--@private
function M._dispatch_file_created(fname)
  dispatch(M.Event.FileCreated, { fname = fname })
end

--@private
function M._dispatch_folder_created(folder_name)
  dispatch(M.Event.FolderCreated, { folder_name = folder_name })
end

--@private
function M._dispatch_folder_removed(folder_name)
  dispatch(M.Event.FolderRemoved, { folder_name = folder_name })
end

--@private
function M._dispatch_on_tree_pre_open()
  dispatch(M.Event.TreePreOpen, nil)
end

--@private
function M._dispatch_on_tree_open()
  dispatch(M.Event.TreeOpen, nil)
end

--@private
function M._dispatch_on_tree_close()
  dispatch(M.Event.TreeClose, nil)
end

--@private
function M._dispatch_on_tree_resize(size)
  dispatch(M.Event.Resize, size)
end

--@private
function M._dispatch_tree_attached_post(buf)
  dispatch(M.Event.TreeAttachedPost, buf)
end

--@private
function M._dispatch_on_tree_rendered(bufnr, winnr)
  dispatch(M.Event.TreeRendered, { bufnr = bufnr, winnr = winnr })
end

return M
