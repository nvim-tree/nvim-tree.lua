---@meta
error("Cannot require a meta file")


---Optionally {persist} bookmarks to a json file:
---- `true` use default: `stdpath("data") .. "/nvim-tree-bookmarks.json"`
---- `false` do not persist
---- `string` absolute path of your choice
---
---@class nvim_tree.config.bookmarks
---
---(default: `false`)
---@field persist? boolean|string
