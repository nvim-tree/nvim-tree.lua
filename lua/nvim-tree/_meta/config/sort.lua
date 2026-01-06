---@meta
error("Cannot require a meta file")

---@class nvim_tree.Config.Sort
---@field sorter? nvim_tree.SortOption|fun(nodes: table): nil Changes how files within the same directory are sorted. Can be one of `"name"`, `"case_sensitive"`, `"modification_time"`, `"extension"`, `"suffix"`, `"filetype"` or a function. `"extension"` uses all suffixes e.g. `foo.tar.gz` -> `.tar.gz` `"suffix"` uses the last e.g. `.gz` Default: `"name"` Function may perform a sort or return a string with one of the above methods. It is passed a table of nodes to be sorted, each node containing: - `absolute_path`: `string` - `executable`: `boolean` - `extension`: `string` - `filetype`: `string` - `link_to`: `string` - `name`: `string` - `type`: `"directory"` | `"file"` | `"link"`
---@field folders_first? boolean Sort folders before files. Has no effect when |nvim-tree.sort.sorter| is a function. Default: `true` @see nvim-tree.sort.sorter
---@field files_first? boolean Sort files before folders. Has no effect when |nvim-tree.sort.sorter| is a function. If set to `true` it overrides |nvim-tree.sort.folders_first|. Default: `false` @see nvim-tree.sort.sorter @see nvim-tree.sort.folders_first

