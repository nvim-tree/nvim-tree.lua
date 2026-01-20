---@meta

local events = require("nvim-tree.events")

local nvim_tree = { api = { events = {} } }

---
---Register a handler for an event, see [nvim-tree-events].
---
---@param event_type string [nvim_tree_events_kind]
---@param callback fun(payload: table?)
function nvim_tree.api.events.subscribe(event_type, callback) end

nvim_tree.api.events.Event = events.Event

return nvim_tree.api.events
