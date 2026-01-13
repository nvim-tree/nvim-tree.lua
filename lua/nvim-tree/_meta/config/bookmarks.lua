---@meta
error("Cannot require a meta file")


---@brief
---Optionally {persist} bookmarks to a json file:
---- `true` use default: `stdpath("data") .. "/nvim-tree-bookmarks.json"`
---- `false` do not persist
---- `string` absolute path of your choice



---@class nvim_tree.Config.Bookmarks
---
---(default: `false`)
---@field persist? boolean|string
