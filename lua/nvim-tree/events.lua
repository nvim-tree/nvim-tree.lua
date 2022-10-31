local notify = require "nvim-tree.notify"

local M = {}

local global_handlers = {}

M.Event = {
  Ready = "Ready",
  NodeRenamed = "NodeRenamed",
  TreeOpen = "TreeOpen",
  TreeClose = "TreeClose",
  FileCreated = "FileCreated",
  FileRemoved = "FileRemoved",
  FolderCreated = "FolderCreated",
  FolderRemoved = "FolderRemoved",
  Resize = "Resize",
}

local function get_handlers(event_name)
  return global_handlers[event_name] or {}
end

function M.subscribe(event_name, handler)
  local handlers = get_handlers(event_name)
  table.insert(handlers, handler)
  global_handlers[event_name] = handlers
end

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
function M._dispatch_node_renamed(old_name, new_name)
  dispatch(M.Event.NodeRenamed, { old_name = old_name, new_name = new_name })
end

--@private
function M._dispatch_file_removed(fname)
  dispatch(M.Event.FileRemoved, { fname = fname })
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

--- @deprecated
function M.on_nvim_tree_ready(handler)
  M.subscribe(M.Event.Ready, handler)
end

--- @deprecated
function M.on_node_renamed(handler)
  M.subscribe(M.Event.NodeRenamed, handler)
end

--- @deprecated
function M.on_file_created(handler)
  M.subscribe(M.Event.FileCreated, handler)
end

--- @deprecated
function M.on_file_removed(handler)
  M.subscribe(M.Event.FileRemoved, handler)
end

--- @deprecated
function M.on_folder_created(handler)
  M.subscribe(M.Event.FolderCreated, handler)
end

--- @deprecated
function M.on_folder_removed(handler)
  M.subscribe(M.Event.FolderRemoved, handler)
end

--- @deprecated
function M.on_tree_open(handler)
  M.subscribe(M.Event.TreeOpen, handler)
end

--- @deprecated
function M.on_tree_close(handler)
  M.subscribe(M.Event.TreeClose, handler)
end

--- @deprecated
function M.on_tree_resize(handler)
  M.subscribe(M.Event.Resize, handler)
end

return M
