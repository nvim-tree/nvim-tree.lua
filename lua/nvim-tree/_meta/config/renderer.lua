---@meta
error("Cannot require a meta file")



---@alias nvim_tree.config.renderer.highlight "none"|"icon"|"name"|"all"

---@alias nvim_tree.config.renderer.hidden_display "none"|"simple"|"all"|(fun(hidden_stats: table<string, integer>): string)

---@alias nvim_tree.config.renderer.icons.placement "before"|"after"|"signcolumn"|"right_align"



---Controls the appearance of the tree.
---
---See [nvim-tree-icons-highlighting] for {highlight_} and {decorators} fields.
---
---{root_folder_label} has 3 forms:
---- `string`: [filename-modifiers] format string, default `":~:s?$?/..?"`
---- `boolean`: `true` to disable
---- `fun(root_cwd: string): string`: return a literal string from root's absolute path e.g.
---```lua
---my_root_folder_label = function(path)
---  return ".../" .. vim.fn.fnamemodify(path, ":t")
---end
---```
---@class nvim_tree.config.renderer
---
---Appends a trailing slash to folder and symlink folder target names.
---(default: `false`)
---@field add_trailing? boolean
---
---Compact folders that only contain a single folder into one node. Function variant takes the relative path of grouped folders and returns a string to be displayed.
---(default: `false`)
---@field group_empty? boolean|(fun(relative_path: string): string)
---
---Display nodes whose name length is wider than the width of nvim-tree window in floating window.
---(default: `false`)
---@field full_name? boolean
---
---(default: `":~:s?$?/..?"`)
---@field root_folder_label? string|boolean|(fun(root_cwd: string): string)
---
---Number of spaces for each tree nesting level. Minimum 1.
---(default: `2`)
---@field indent_width? integer
---
---[nvim-tree-hidden-display]
---(default: `none`)
---@field hidden_display? nvim_tree.config.renderer.hidden_display
---
---Appends an arrow followed by the target of the symlink.
---(default: `true`)
---@field symlink_destination? boolean
---
---(default: `{ "Git", "Open", "Hidden", "Modified", "Bookmark", "Diagnostics", "Copied", "Cut", }`)
---@field decorators? (string|nvim_tree.api.decorator.UserDecorator)[]
---
---(default: `"none"`)
---@field highlight_git? nvim_tree.config.renderer.highlight
---
---(default: `"none"`)
---@field highlight_opened_files? nvim_tree.config.renderer.highlight
---
---(default: `"none"`)
---@field highlight_hidden? nvim_tree.config.renderer.highlight
---
---(default: `"none"`)
---@field highlight_modified? nvim_tree.config.renderer.highlight
---
---(default: `"none"`)
---@field highlight_bookmarks? nvim_tree.config.renderer.highlight
---
---(default: `"none"`)
---@field highlight_diagnostics? nvim_tree.config.renderer.highlight
---
---(default: `"name"`)
---@field highlight_clipboard? nvim_tree.config.renderer.highlight
---
---Highlight special files and directories with `NvimTreeSpecial*`.
---(default: `{ "Cargo.toml", "Makefile", "README.md", "readme.md", }`)
---@field special_files? string[]
---
---[nvim_tree.config.renderer.indent_markers]
---@field indent_markers? nvim_tree.config.renderer.indent_markers
---
---[nvim_tree.config.renderer.icons]
---@field icons? nvim_tree.config.renderer.icons



---@class nvim_tree.config.renderer.indent_markers
---
---Display indent markers when folders are open.
---(default: `false`)
---@field enable? boolean
---
---Display folder arrows in the same column as indent marker when using [nvim_tree.config.renderer.icons.padding] {folder_arrow}
---(default: `true`)
---@field inline_arrows? boolean
---
---@field icons? nvim_tree.config.renderer.indent_markers.icons



---[nvim_tree.config.renderer.indent_markers.icons]()
---Before the file/directory, length 1.
---@class nvim_tree.config.renderer.indent_markers.icons
---@inlinedoc
---
---(default: `"└"`)
---@field corner? string
---(default: `"│"`)
---@field edge? string
---(default: `"│"`)
---@field item? string
---(default: `"─"`)
---@field bottom? string
---(default: `" "`)
---@field none? string



---Icons and separators
---
---See [nvim-tree-icons-highlighting] for: {_placement} fields.
---@class nvim_tree.config.renderer.icons
---
---(default: `before`)
---@field git_placement? nvim_tree.config.renderer.icons.placement
---
---(default: `after`)
---@field hidden_placement? nvim_tree.config.renderer.icons.placement
---
---(default: `after`)
---@field modified_placement? nvim_tree.config.renderer.icons.placement
---
---(default: `signcolumn`)
---@field bookmarks_placement? nvim_tree.config.renderer.icons.placement
---
---(default: `signcolumn`)
---@field diagnostics_placement? nvim_tree.config.renderer.icons.placement
---
---@field padding? nvim_tree.config.renderer.icons.padding
---
---Separator between symlink source and target.
---(default: `" ➛ "`)
---@field symlink_arrow? string
---
---[nvim_tree.config.renderer.icons.show]
---@field show? nvim_tree.config.renderer.icons.show
---
---[nvim_tree.config.renderer.icons.glyphs]
---@field glyphs? nvim_tree.config.renderer.icons.glyphs
---
---[nvim_tree.config.renderer.icons.web_devicons]
---@field web_devicons? nvim_tree.config.renderer.icons.web_devicons



---Configure optional plugin `nvim-tree/nvim-web-devicons`, see [nvim-tree-icons-highlighting].
---
---@class nvim_tree.config.renderer.icons.web_devicons
---
---@field file? nvim_tree.config.renderer.icons.web_devicons.file
---
---@field folder? nvim_tree.config.renderer.icons.web_devicons.folder



---[nvim_tree.config.renderer.icons.web_devicons.file]()
---@class nvim_tree.config.renderer.icons.web_devicons.file
---@inlinedoc
---
---(default: `true`)
---@field enable? boolean
---
---(default: `true`)
---@field color? boolean


---[nvim_tree.config.renderer.icons.web_devicons.folder]()
---@class nvim_tree.config.renderer.icons.web_devicons.folder
---@inlinedoc
---
---(default: `false`)
---@field enable? boolean
---
---(default: `true`)
---@field color? boolean



---[nvim_tree.config.renderer.icons.padding]()
---@class nvim_tree.config.renderer.icons.padding
---@inlinedoc
---
---Between icon and filename.
---(default: `" "`)
---@field icon? string
---
---Between folder arrow icon and file/folder icon.
---(default: `" "`)
---@field folder_arrow? string



---See [nvim-tree-icons-highlighting].
---@class nvim_tree.config.renderer.icons.show
---
---(default: `true`)
---@field file? boolean
---
---(default: `true`)
---@field folder? boolean
---
---(default: `true`)
---@field git? boolean
---
---(default: `true`)
---@field modified? boolean
---
---(default: `false`)
---@field hidden? boolean
---
---(default: `true`)
---@field diagnostics? boolean
---
---(default: `true`)
---@field bookmarks? boolean
---
---Show a small arrow before the folder node. Arrow will be a part of the node when using [nvim_tree.config.renderer.indent_markers].
---(default: `true`)
---@field folder_arrow? boolean



---See [nvim-tree-icons-highlighting].
---
---Glyphs that appear in the sign column must have length <= 2
---@class nvim_tree.config.renderer.icons.glyphs
---
---Files
---(default: `""`)
---@field default? string
---
---(default: `""`)
---@field symlink? string
---
---(default: `"󰆤"`)
---@field bookmark? string
---
---(default: `"●"`)
---@field modified? string
---
---(default: `"󰜌"`)
---@field hidden? string
---
---@field folder? nvim_tree.config.renderer.icons.glyphs.folder
---
---@field git? nvim_tree.config.renderer.icons.glyphs.git



---[nvim_tree.config.renderer.icons.glyphs.folder]()
---@class nvim_tree.config.renderer.icons.glyphs.folder
---@inlinedoc
---(default: left arrow)
---@field arrow_closed? string
---(default: down arrow)
---@field arrow_open? string
---(default: `""`)
---@field default? string
---(default: `""`)
---@field open? string
---(default: `""`)
---@field empty? string
---(default: `""`)
---@field empty_open? string
---(default: `""`)
---@field symlink? string
---(default: `""`)
---@field symlink_open? string



---[nvim_tree.config.renderer.icons.glyphs.git]()
---@class nvim_tree.config.renderer.icons.glyphs.git
---@inlinedoc
---(default: `"✗"`)
---@field unstaged? string
---(default: `"✓"`)
---@field staged? string
---(default: `""`)
---@field unmerged? string
---(default: `"➜"`)
---@field renamed? string
---(default: `"★"`)
---@field untracked? string
---(default: `""`)
---@field deleted? string
---(default: `"◌"`)
---@field ignored? string
