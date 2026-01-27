---@meta
error("Cannot require a meta file")



---Use file system watchers (libuv `uv_fs_event_t`) to monitor the filesystem for changes and update the tree.
---
---With this feature, the tree will be partially updated on specific directory changes, resulting in better performance.
---
---Watchers may be disabled for absolute directory paths via {ignore_dirs}.
--- - A list of [vim.regex] to match a path, backslash escaped e.g. `"my-proj/\\.build$"` OR
--- - A function that is passed an absolute path and returns `true` to disable
---This may be useful when a path is not in `.gitignore` or git integration is disabled.
---
---On runaway consecutive filesystem events for a single directory with an interval < [nvim-tree.filesystem_watchers.debounce_delay]:
---- The filesystem watcher will be disabled for that directory.
---- A warning notification will be shown.
---- Consider adding this directory to [filesystem_watchers.ignore_dirs]
---
---The runaway threshold is controlled by {max_events} and has been observed when running on Windows PowerShell: an infinite number of filesystem events were raised and Nvim hangs.
---
---@class nvim_tree.config.filesystem_watchers
---
---(default: `true`)
---@field enable? boolean
---
---Idle milliseconds between filesystem change and tree update.
---(default: `50`)
---@field debounce_delay? integer
---
---Disable for specific directories.
---(default: `{ "/.ccls-cache", "/build", "/node_modules", "/target", }`)
---@field ignore_dirs? string[]|(fun(path: string): boolean)
---
---Disable for a single directory after consecutive events with an interval < [nvim-tree.filesystem_watchers.debounce_delay].
---(default: `100`)
---@field max_events? integer
