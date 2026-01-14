---@meta
error("Cannot require a meta file")



---@alias nvim_tree.Config.Renderer.HighlightPlacement "none"|"icon"|"name"|"all"

---@alias nvim_tree.Config.Renderer.HiddenDisplay "none"|"simple"|"all"|(fun(hidden_stats: table<string, integer>): string)

---@alias nvim_tree.Config.Renderer.Icons.Placement "before"|"after"|"signcolumn"|"right_align"



---@brief
---Controls the appearance of the tree.
---
---<pre>help
---Icons and highlighting in ascending order of precedence:
---
--- |nvim_tree.Config.Renderer.Icons.Show|  Requires                      |nvim_tree.Config.Renderer.Icons|  |nvim_tree.Config.Renderer|  Devicons?  Highlight                   Icon(s)
--- {file}                                 -                             -                                -                         yes        `NvimTreeNo*`, `NvimTreeFile*`  |nvim_tree.Config.Renderer.Icons.Glyphs| {default}
--- {folder}                               -                             -                                -                         yes        `NvimTree*Folder*`            |nvim_tree.Config.Renderer.Icons.Glyphs.Folder|
--- {git}                                 |nvim_tree.Config.Git|          {git_placement}                  {highlight_git}            yes        `NvimTreeGit*`                |nvim_tree.Config.Renderer.Icons.Glyphs.Git|
---  -                                     -                             -                               {highlight_opened_files}   no         `NvimTreeOpened*`              -
--- {hidden}                               -                            {hidden_placement}               {highlight_hidden}         no         `NvimTreeHidden*`             |nvim_tree.Config.Renderer.Icons.Glyphs| {hidden}
--- {modified}                            |nvim_tree.Config.Modified|     {modified_placement}             {highlight_modified}       no         `NvimTreeModified*`           |nvim_tree.Config.Renderer.Icons.Glyphs| {modified}
--- {bookmarks}                            -                            {bookmarks_placement}            {highlight_bookmarks}      no         `NvimTreeBookmark*`           |nvim_tree.Config.Renderer.Icons.Glyphs| {bookmark}
--- {diagnostics}                         |nvim_tree.Config.Diagnostics|  {diagnostics_placement}          {highlight_diagnostics}    no         `NvimTreeDiagnostic*`         |nvim_tree.Config.Diagnostics.Icons|
---  -                                     -                             -                               {highlight_clipboard}      no         `NvimTreeC*HL`                 -
---
---</pre>
---
---{highlight_} options [nvim_tree.Config.Renderer.HighlightPlacement]()
---- `none`: no highlighting
---- `icon`: icon only
---- `name`: name only
---- `all`:  icon and name
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



---@class nvim_tree.Config.Renderer
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
---@field hidden_display? nvim_tree.Config.Renderer.HiddenDisplay
---
---Appends an arrow followed by the target of the symlink.
---(default: `true`)
---@field symlink_destination? boolean
---
---Highlighting and icons for the nodes, in increasing order of precedence. Strings specify builtin decorators. See [nvim-tree-decorators].
---(default: `{ "Git", "Open", "Hidden", "Modified", "Bookmark", "Diagnostics", "Copied", "Cut", }`)
---@field decorators? (string|nvim_tree.api.decorator.UserDecorator)[]
---
---Git status.
---(default: `none`)
---@field highlight_git? nvim_tree.Config.Renderer.HighlightPlacement
---
---[bufloaded()] files.
---(default: `none`)
---@field highlight_opened_files? nvim_tree.Config.Renderer.HighlightPlacement
---
---Hidden (dotfiles) files and directories.
---(default: `none`)
---@field highlight_hidden? nvim_tree.Config.Renderer.HighlightPlacement
---
---Modified files.
---(default: `none`)
---@field highlight_modified? nvim_tree.Config.Renderer.HighlightPlacement
---
---Bookmarked files and directories.
---(default: `none`)
---@field highlight_bookmarks? nvim_tree.Config.Renderer.HighlightPlacement
---
---Diagnostic status.
---(default: `none`)
---@field highlight_diagnostics? nvim_tree.Config.Renderer.HighlightPlacement
---
---Copied and cut.
---(default: `name`)
---@field highlight_clipboard? nvim_tree.Config.Renderer.HighlightPlacement
---
---Highlight special files and directories with `NvimTreeSpecial*`.
---(default: `{ "Cargo.toml", "Makefile", "README.md", "readme.md", }`)
---@field special_files? string[]
---
---[nvim_tree.Config.Renderer.IndentMarkers]
---@field indent_markers? nvim_tree.Config.Renderer.IndentMarkers
---
---[nvim_tree.Config.Renderer.Icons]
---@field icons? nvim_tree.Config.Renderer.Icons


---@class nvim_tree.Config.Renderer.IndentMarkers
---
---Display indent markers when folders are open.
---(default: `false`)
---@field enable? boolean
---
---Display folder arrows in the same column as indent marker when using [nvim_tree.Config.Renderer.Icons.Padding] {folder_arrow}
---(default: `true`)
---@field inline_arrows? boolean
---
---@field icons? nvim_tree.Config.Renderer.IndentMarkers.Icons



---[nvim_tree.Config.Renderer.IndentMarkers.Icons]()
---Before the file/directory, length 1.
---@class nvim_tree.Config.Renderer.IndentMarkers.Icons
---@inlinedoc
---
---(default: `└` )
---@field corner? string
---(default: `│` )
---@field edge? string
---(default: `│` )
---@field item? string
---(default: `─` )
---@field bottom? string
---(default: ` ` )
---@field none? string



---Icons and separators.
---
---{_placement} options [nvim_tree.Config.Renderer.Icons.Placement]()
---- `before`: before file/folder, after the file/folders icons
---- `after`: after file/folder
---- `signcolumn`: far left, requires [nvim_tree.Config.View] {signcolumn}.
---- `right_align`: far right
---
---@class nvim_tree.Config.Renderer.Icons
---
---[nvim_tree.Config.Renderer.Icons.WebDevicons]
---Use optional plugin `nvim-tree/nvim-web-devicons`
---@field web_devicons? nvim_tree.Config.Renderer.Icons.WebDevicons
---
---(default: `before`)
---@field git_placement? nvim_tree.Config.Renderer.Icons.Placement
---
---Requires [nvim_tree.Config.Diagnostics].
---(default: `signcolumn`)
---@field diagnostics_placement? nvim_tree.Config.Renderer.Icons.Placement
---
---Requires [nvim_tree.Config.Modified].
---(default: `after`)
---@field modified_placement? nvim_tree.Config.Renderer.Icons.Placement
---
---(default: `after`)
---@field hidden_placement? nvim_tree.Config.Renderer.Icons.Placement
---
---(default: `signcolumn`)
---@field bookmarks_placement? nvim_tree.Config.Renderer.Icons.Placement
---
---@field padding? nvim_tree.Config.Renderer.Icons.Padding
---
---Separator between symlink source and target.
---(default: ` ➛ `)
---@field symlink_arrow? string
---
---[nvim_tree.Config.Renderer.Icons.Show]
---@field show? nvim_tree.Config.Renderer.Icons.Show
---
---[nvim_tree.Config.Renderer.Icons.Glyphs]
---@field glyphs? nvim_tree.Config.Renderer.Icons.Glyphs



---Configure optional plugin `nvim-tree/nvim-web-devicons`.
---
---@class nvim_tree.Config.Renderer.Icons.WebDevicons
---
---@field file? nvim_tree.Config.Renderer.Icons.WebDevicons.File
---
---@field folder? nvim_tree.Config.Renderer.Icons.WebDevicons.Folder



---[nvim_tree.Config.Renderer.Icons.WebDevicons.File]()
---@class nvim_tree.Config.Renderer.Icons.WebDevicons.File
---@inlinedoc
---
---(default: `true`)
---@field enable? boolean
---
---(default: `true`)
---@field color? boolean


---[nvim_tree.Config.Renderer.Icons.WebDevicons.Folder]()
---@class nvim_tree.Config.Renderer.Icons.WebDevicons.Folder
---@inlinedoc
---
---(default: `false`)
---@field enable? boolean
---
---(default: `true`)
---@field color? boolean



---[nvim_tree.Config.Renderer.Icons.Padding]()
---@class nvim_tree.Config.Renderer.Icons.Padding
---@inlinedoc
---
---Between icon and filename.
---(default: ` `)
---@field icon? string
---
---Between folder arrow icon and file/folder icon.
---(default: ` `)
---@field folder_arrow? string



---Control which icons are displayed.
---@class nvim_tree.Config.Renderer.Icons.Show
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
---Show a small arrow before the folder node. Arrow will be a part of the node when using [nvim_tree.Config.Renderer.IndentMarkers].
---(default: `true`)
---@field folder_arrow? boolean



---Glyphs that appear in the sign column must have length <= 2
---
---@class nvim_tree.Config.Renderer.Icons.Glyphs
---
---Files
---(default: `` )
---@field default? string
---
---(default: `` )
---@field symlink? string
---
---(default: `󰆤` )
---@field bookmark? string
---
---(default: `●` )
---@field modified? string
---
---(default: `󰜌` )
---@field hidden? string
---
---@field folder? nvim_tree.Config.Renderer.Icons.Glyphs.Folder
---
---@field git? nvim_tree.Config.Renderer.Icons.Glyphs.Git



---[nvim_tree.Config.Renderer.Icons.Glyphs.Folder]()
---@class nvim_tree.Config.Renderer.Icons.Glyphs.Folder
---@inlinedoc
---(default: left arrow)
---@field arrow_closed? string
---(default: down arrow)
---@field arrow_open? string
---(default: `` )
---@field default? string
---(default: `` )
---@field open? string
---(default: `` )
---@field empty? string
---(default: `` )
---@field empty_open? string
---(default: `` )
---@field symlink? string
---(default: `` )
---@field symlink_open? string



---[nvim_tree.Config.Renderer.Icons.Glyphs.Git]()
---@class nvim_tree.Config.Renderer.Icons.Glyphs.Git
---@inlinedoc
---(default: `✗` )
---@field unstaged? string
---(default: `✓` )
---@field staged? string
---(default: `` )
---@field unmerged? string
---(default: `➜` )
---@field renamed? string
---(default: `★` )
---@field untracked? string
---(default: `` )
---@field deleted? string
---(default: `◌` )
---@field ignored? string
