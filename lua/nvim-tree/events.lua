local notify = require("nvim-tree.notify")
local Event = require("nvim-tree._meta.api.events").Event

local M = {}

local global_handlers = {}

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
  dispatch(Event.Ready)
end

--@private
function M._dispatch_will_rename_node(old_name, new_name)
  dispatch(Event.WillRenameNode, { old_name = old_name, new_name = new_name })
end

--@private
function M._dispatch_node_renamed(old_name, new_name)
  dispatch(Event.NodeRenamed, { old_name = old_name, new_name = new_name })
end

--@private
function M._dispatch_will_remove_file(fname)
  dispatch(Event.WillRemoveFile, { fname = fname })
end

--@private
function M._dispatch_file_removed(fname)
  dispatch(Event.FileRemoved, { fname = fname })
end

--@private
function M._dispatch_will_create_file(fname)
  dispatch(Event.WillCreateFile, { fname = fname })
end

--@private
function M._dispatch_file_created(fname)
  dispatch(Event.FileCreated, { fname = fname })
end

--@private
function M._dispatch_folder_created(folder_name)
  dispatch(Event.FolderCreated, { folder_name = folder_name })
end

--@private
function M._dispatch_folder_removed(folder_name)
  dispatch(Event.FolderRemoved, { folder_name = folder_name })
end

--@private
function M._dispatch_on_tree_pre_open()
  dispatch(Event.TreePreOpen, nil)
end

--@private
function M._dispatch_on_tree_open()
  dispatch(Event.TreeOpen, nil)
end

--@private
function M._dispatch_on_tree_close()
  dispatch(Event.TreeClose, nil)
end

--@private
function M._dispatch_on_tree_resize(size)
  dispatch(Event.Resize, size)
end

--@private
function M._dispatch_tree_attached_post(buf)
  dispatch(Event.TreeAttachedPost, buf)
end

--@private
function M._dispatch_on_tree_rendered(bufnr, winnr)
  dispatch(Event.TreeRendered, { bufnr = bufnr, winnr = winnr })
end

return M
