---@meta
error("Cannot require a meta file")



---@brief
---Open files or directories via the OS.
---
---Nvim:
---- `>=` 0.10 uses [vim.ui.open()] unless {cmd} is specified
---- `<` 0.10 calls external {cmd}:
---   - UNIX: `xdg-open`
---   - macOS: `open`
---   - Windows: `cmd`
---
---Once nvim-tree minimum Nvim version is updated to 0.10, these options will no longer be necessary and will be removed.



---@class nvim_tree.Config.SystemOpen
---
---The open command itself
---(default: `xdg-open`, `open` or `cmd`)
---@field cmd? string
---
---Optional argument list. Leave empty for OS specific default.
---(default: `{}` or `{ "/c", "start", '""' }` on windows)
---@field args? string[]
