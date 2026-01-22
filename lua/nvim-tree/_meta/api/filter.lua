---@meta
local nvim_tree = { api = { filter = {} } }

---
---Toggle [nvim_tree.config.filters] {enable} all filters.
---
function nvim_tree.api.filter.toggle() end

nvim_tree.api.filter.live = {}

---
---Enter live filter mode. Opens an input window with [filetype] `NvimTreeFilter`
---
function nvim_tree.api.filter.live.start() end

---
---Exit live filter mode.
---
function nvim_tree.api.filter.live.clear() end

nvim_tree.api.filter.git = {}

---
---Toggle [nvim_tree.config.filters] {git_clean} filter.
---
function nvim_tree.api.filter.git.clean.toggle() end

---
---Toggle [nvim_tree.config.filters] {git_ignored} filter.
---
function nvim_tree.api.filter.git.ignored.toggle() end

nvim_tree.api.filter.dotfiles = {}

---
---Toggle [nvim_tree.config.filters] {dotfiles} filter.
---
function nvim_tree.api.filter.dotfiles.toggle() end

nvim_tree.api.filter.no_buffer = {}

---
---Toggle [nvim_tree.config.filters] {no_buffer} filter.
---
function nvim_tree.api.filter.no_buffer.toggle() end

nvim_tree.api.filter.no_bookmark = {}

---
---Toggle [nvim_tree.config.filters] {no_bookmark} filter.
---
function nvim_tree.api.filter.no_bookmark.toggle() end

nvim_tree.api.filter.custom = {}

---
---Toggle [nvim_tree.config.filters] {custom} filter.
---
function nvim_tree.api.filter.custom.toggle() end

return nvim_tree.api.filter
