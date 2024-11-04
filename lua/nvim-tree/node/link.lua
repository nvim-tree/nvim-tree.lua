local Object = require("nvim-tree.classic")

---@class (exact) LinkNode: Object
---@field link_to string
---@field protected fs_stat_target uv.fs_stat.result
local LinkNode = Object:extend()

return LinkNode
