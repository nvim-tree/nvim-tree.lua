---@meta
error("Cannot require a meta file")

---Update the focused file on [BufEnter], uncollapsing folders recursively.
---
---@class nvim_tree.Config.UpdateFocusedFile
---
---(default: `false`)
---@field enable? boolean
---
---[nvim_tree.Config.UpdateFocusedFile.UpdateRoot]
---@field update_root? nvim_tree.Config.UpdateFocusedFile.UpdateRoot
---
---A function called on [BufEnter] that returns true if the file should not be focused when opening.
---(default: `false`)
---@field exclude? boolean|(fun(args: vim.api.keyset.create_autocmd.callback_args): boolean)


---Update the root directory of the tree if the file is not under the current root directory.
---
---Prefers vim's cwd and [nvim_tree.Config] {root_dirs}, falling back to the directory containing the file.
---
---Requires [nvim_tree.Config.UpdateFocusedFile]
---
---@class nvim_tree.Config.UpdateFocusedFile.UpdateRoot
---
---(default: `false`)
---@field enable? boolean
---
---List of buffer names and filetypes that will not update the root dir of the tree if the file isn't found under the current root directory.
---(default: `{}`)
---@field ignore_list? string[]
