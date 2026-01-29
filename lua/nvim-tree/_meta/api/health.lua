---@meta
local nvim_tree = { api = { health = {} } }

---
---Open a new buffer displaying all nvim-tree highlight groups, their link chain and concrete definition.
---
---Similar to `:so $VIMRUNTIME/syntax/hitest.vim` as per |:highlight|
---
function nvim_tree.api.health.hi_test() end

return nvim_tree.api.health
