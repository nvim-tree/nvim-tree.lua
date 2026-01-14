---@meta
error("Cannot require a meta file")



---@brief
---Git operations are run in the background thus status may not immediately appear.
---
---Processes will be killed if they exceed {timeout} ms. Git integration will be disabled following 5 timeouts and you will be notified.
---
---Git integration may be disabled for git top-level directories via {disable_for_dirs}:
--- - A list of relative paths evaluated with [fnamemodify()] `:p` OR
--- - A function that is passed an absolute path and returns `true` to disable
---
---See [nvim-tree-icons-highlighting].



---@class nvim_tree.Config.Git
---
---(default: `true`)
---@field enable? boolean
---
---Show status icons of children when directory itself has no status icon
---(default: `true`)
---@field show_on_dirs? boolean
---
---Show status icons of children on directories that are open. Requires {show_on_dirs}.
---(default: `true`)
---@field show_on_open_dirs? boolean
---
---Disable for top level paths.
---(default: `{}`)
---@field disable_for_dirs? string[]|(fun(path: string): boolean)
---
---`git` processes timeout milliseconds.
---(default: `400`)
---@field timeout? integer
---
---Use `cygpath` if available to resolve paths for git.
---(Default: `false`)
---@field cygwin_support? boolean
