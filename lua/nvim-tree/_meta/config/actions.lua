---@meta
error("Cannot require a meta file")

---@class nvim_tree.Config.Actions
---
---Use the system clipboard for copy/paste. Copied text will be stored in registers `+` (system), otherwise, it will be stored in `1` and `"`
---(default: `true`)
---@field use_system_clipboard? boolean
---
---[nvim_tree.Config.Actions.ChangeDir]
---@field change_dir? nvim_tree.Config.Actions.ChangeDir
---
---[nvim_tree.Config.Actions.ExpandAll]
---@field expand_all? nvim_tree.Config.Actions.ExpandAll
---
---[nvim_tree.Config.Actions.FilePopup]
---@field file_popup? nvim_tree.Config.Actions.FilePopup
---
---[nvim_tree.Config.Actions.OpenFile]
---@field open_file? nvim_tree.Config.Actions.OpenFile
---
---[nvim_tree.Config.Actions.RemoveFile]
---@field remove_file? nvim_tree.Config.Actions.RemoveFile


--- vim [current-directory] behaviour
---@class nvim_tree.Config.Actions.ChangeDir
---
---Change the working directory when changing directories in the tree
---(default: `true`)
---@field enable? boolean
---
---Use `:cd` instead of `:lcd` when changing directories.
---(default: `false`)
---@field global? boolean
---
--- Restrict changing to a directory above the global cwd.
---(default: `false`)
---@field restrict_above_cwd? boolean


---Configure [nvim-tree-api.tree.expand_all()] and [nvim-tree-api.node.expand()]
---@class nvim_tree.Config.Actions.ExpandAll
---
---Limit the number of folders being explored when expanding every folders. Avoids hanging neovim when running this action on very large folders.
---(default: `300`)
---@field max_folder_discovery? integer
---
---A list of directories that should not be expanded automatically e.g `{ ".git", "target", "build" }`
---(default: `{}`)
---@field exclude? string[]


---{file_popup} floating window.
---
---{open_win_config} is passed directly to [nvim_open_win()], default:
---```lua
---{
---  col = 1,
---  row = 1,
---  relative = "cursor",
---  border = "shadow",
---  style = "minimal",
---}
---```
---You shouldn't define {width} and {height} values here. They will be overridden to fit the file_popup content.
---@class nvim_tree.Config.Actions.FilePopup
---
---(default: above)
---@field open_win_config? vim.api.keyset.win_config


---Opening files.
---@class nvim_tree.Config.Actions.OpenFile
---
---Closes the explorer when opening a file
---(default: `false`)
---@field quit_on_open? boolean
---
---Prevent new opened file from opening in the same window as the tree.
---(default: `true`)
---@field eject? boolean
---
---Resizes the tree when opening a file
---(default: `true`)
---@field resize_window? boolean
---
---[nvim_tree.Config.Actions.OpenFile.WindowPicker]
---@field window_picker? nvim_tree.Config.Actions.OpenFile.WindowPicker


---A window picker will be shown when there are multiple windows available to open a file. It will show a single character identifier in each window's status line.
---
---When it is not enabled the file will open in the window from which you last opened the tree, obeying {exclude}
---
---You may define a function that should return the window id that will open the node, or `nil` if an invalid window is picked or user cancelled the action. The picker may create a new window.
---
---@class nvim_tree.Config.Actions.OpenFile.WindowPicker
---
---(default: `true`)
---@field enable? boolean
---
---Change the default window picker: string `default` or a function.
---(default: `default`)
---@field picker? string|(fun(): integer)
---
---Identifier characters to use.
---(default: `"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"`)
---@field chars? string
---
---[nvim_tree.Config.Actions.OpenFile.WindowPicker.Exclude]
---@field exclude? nvim_tree.Config.Actions.OpenFile.WindowPicker.Exclude


---Tables of buffer option names mapped to a list of option values. Windows containing matching buffers will not be:
--- - available when using a window picker
--- - selected when not using a window picker
---@class nvim_tree.Config.Actions.OpenFile.WindowPicker.Exclude
---
---(default: `{ "notify", "lazy", "qf", "diff", "fugitive", "fugitiveblame", }`)
---@field filetype? string[]
---
---(default: `{ "nofile", "terminal", "help", }`)
---@field buftype? string[]


---Removing files.
---@class nvim_tree.Config.Actions.RemoveFile
---
---Close any window that displays a file when removing that file from the tree.
---(default: `true`)
---@field close_window? boolean
