---@meta
error("Cannot require a meta file")



---Experimental features that may become default or optional functionality.
---
---In the event of a problem please disable the experiment and raise an issue.
---
---@class nvim_tree.config.experimental
---
---Load the git status of a project in the background the first time the project is shown,
---instead of blocking until `git status` completes. The tree is drawn without git status,
---which is filled in when `git status` completes. Until then the git filters of
---|nvim_tree.config.filters| see no status: {git_ignored} files are shown and {git_clean}
---hides every file, so |nvim_tree.config.update_focused_file| cannot find a file that is
---only shown once the status is known.
---
---{timeout} of |nvim_tree.config.git| still applies: a large repository may need a larger
---{timeout} for `git status` to complete.
---
---Only the first load is in the background. Reloads such as |nvim_tree.api.tree.reload()|
---still block, including those that run while the first load is in progress.
---(default: `false`)
---@field git_async_load? boolean
---
--Example below for future reference:
--
--Buffers opened by nvim-tree will use with relative paths instead of absolute.
--(default: false)
--@field relative_path? boolean
