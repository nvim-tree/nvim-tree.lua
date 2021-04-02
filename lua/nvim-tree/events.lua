local M = {}

local handlers = {}

local Event = {
    NodeRenamed = 'NodeRenamed',
    FileCreated = 'FileCreated',
    FileRemoved = 'FileRemoved',
    FolderCreated = 'FolderCreated',
    FolderRemoved = 'FolderRemoved',
}

local function get_handlers(event_name)
    return handlers[event_name] or {}
end

local function register_handler(event_name, handler)
    handlers[event_name] = table.insert(get_handlers(event_name), handler)
end


local function dispatch(event_name, payload)
    for _, handler in ipairs(get_handlers(event_name)) do
        local success, error = pcall(handler, payload)
        if not success then
            vim.api.nvim_err_writeln('Handler for event ' .. event_name .. ' errored. ' .. vim.inspect(error))
        end
    end
end

--@private
function M._dispatch_node_renamed(old_name, new_name)
    dispatch(Event.NodeRenamed, {old_name=old_name, new_name=new_name})
end

--@private
function M._dispatch_file_removed(fname)
    dispatch(Event.FileRemoved, {fname=fname})
end

--@private
function M._dispatch_file_created(fname)
    dispatch(Event.FileCreated, {fname=fname})
end

--@private
function M._dispatch_folder_created(folder_name)
    dispatch(Event.FolderCreated, {folder_name=folder_name})
end

--@private
function M._dispatch_folder_removed(folder_name)
    dispatch(Event.FolderRemoved, {folder_name=folder_name})
end

--Registers a handler for the NodeRenamed event.
--@param handler (function) Handler with the signature function(payload), where payload is a table containing:
--  - old_name (string) Absolute path to the old node location.
--  - new_name (string) Absolute path to the new node location.
function M.on_node_renamed(handler)
    register_handler(Event.NodeRenamed, handler)
end

--Registers a handler for the FileCreated event.
--@param handler (function) Handler with the signature function(payload), where payload is a table containing:
--  - fname (string) Absolute path to the created file.
function M.on_file_created(handler)
    register_handler(Event.FileCreated, handler)
end

--Registers a handler for the FileRemoved event.
--@param handler (function) Handler with the signature function(payload), where payload is a table containing:
--  - fname (string) Absolute path to the removed file.
function M.on_file_removed(handler)
    register_handler(Event.FileRemoved, handler)
end

--Registers a handler for the FolderCreated event.
--@param handler (function) Handler with the signature function(payload), where payload is a table containing:
--  - folder_name (string) Absolute path to the created folder.
function M.on_folder_created(handler)
    register_handler(Event.FolderCreated, handler)
end

--Registers a handler for the FolderRemoved event.
--@param handler (function) Handler with the signature function(payload), where payload is a table containing:
--  - folder_name (string) Absolute path to the removed folder.
function M.on_folder_removed(handler)
    register_handler(Event.FolderRemoved, handler)
end

return M
