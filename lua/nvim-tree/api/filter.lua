---@meta
local nvim_tree = { api = { filter = { live_filter = {} } } }

---
---Enter live filter mode. Opens an input window with [filetype] `NvimTreeFilter`
---
function nvim_tree.api.filter.live_filter.start() end

---
---Exit live filter mode.
---
function nvim_tree.api.filter.live_filter.clear() end

require("nvim-tree.api.impl").filter(nvim_tree.api.filter)

return nvim_tree.api.filter
