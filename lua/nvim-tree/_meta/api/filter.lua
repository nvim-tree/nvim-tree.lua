---@meta
local nvim_tree = { api = { filter = { live_filter = {} } } }


-- TODO 3088 move tree filters in here

---
---Enter live filter mode. Opens an input window with [filetype] `NvimTreeFilter`
---
function nvim_tree.api.filter.live_filter.start() end

---
---Exit live filter mode.
---
function nvim_tree.api.filter.live_filter.clear() end

return nvim_tree.api.filter
