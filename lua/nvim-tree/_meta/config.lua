---@meta
error("Cannot require a meta file")

-- The nvim_tree global namespace exists at runtime but cannot be declared in meta files.
-- This suppression allows referencing the namespace for type definitions.
---@diagnostic disable: undefined-global

--
-- Type Aliases for Enums
--

---@alias nvim_tree.PlacementOption "before"|"after"|"signcolumn"|"right_align"
---@alias nvim_tree.HighlightOption "none"|"icon"|"name"|"all"
---@alias nvim_tree.HiddenDisplayOption "none"|"simple"|"all"
---@alias nvim_tree.SortOption "name"|"case_sensitive"|"modification_time"|"extension"|"suffix"|"filetype"
---@alias nvim_tree.HelpSortOption "key"|"desc"

--
-- nvim-tree Setup Config
--

---@class nvim_tree.Config
---
---Runs when creating the nvim-tree buffer. Use this to set your nvim-tree specific mappings. See |nvim-tree-mappings|. When `on_attach` is not a function, |nvim-tree-mappings-default| will be called.
---@field on_attach? string|fun(bufnr: integer)
---
---Keeps the cursor on the first letter of the filename when moving in the tree.
---(default: `false`)
---@field hijack_cursor? boolean 
---
---Reloads the explorer every time a buffer is written to.
---(default: `true`)
---@field auto_reload_on_write? boolean
---
---Completely disable |netrw|, see |nvim-tree-netrw| for details. It is strongly advised to eagerly disable netrw, due to race conditions at vim startup.
---(default: `false`)
---@field disable_netrw? boolean 
---
---Hijack netrw windows, ignored when `disable_netrw` is `true`
---(default: `true`)
---@field hijack_netrw? boolean 
---
---Opens in place of the unnamed buffer if it's empty.
---(default: `false`)
---TODO reinstate this one when formatting is done #2934
-----@field hijack_unnamed_buffer_when_opening? boolean
---@field hubwo? boolean
---
---Preferred root directories. Only relevant when |nvim_tree.Config.UpdateFocusedFile| `update_root` is `true`
---@field root_dirs? string[]
---
---Prefer startup root directory when updating root directory of the tree. Only relevant when |nvim_tree.Config.UpdateFocusedFile| `update_root` is `true`
---(default: `false`)
---@field prefer_startup_root? boolean 
---
---Changes the tree root directory on |DirChanged| and refreshes the tree.
---(default: `false`)
---@field sync_root_with_cwd? boolean
---
---Automatically reloads the tree on |BufEnter| nvim-tree.
---(default: `false`)
---@field reload_on_bufenter? boolean
---
---Change cwd of nvim-tree to that of new buffer's when opening nvim-tree.
---(default: `false`)
---@field respect_buf_cwd? boolean 
---
---Use |vim.ui.select| style prompts. Necessary when using a UI prompt decorator such as dressing.nvim or telescope-ui-select.nvim
---(default: `false`)
---@field select_prompts? boolean 
---
---|nvim_tree.Config.Sort|
---@field sort? nvim_tree.Config.Sort
---
---|nvim_tree.Config.View|
---@field view? nvim_tree.Config.View
---
---|nvim_tree.Config.Renderer|
---@field renderer? nvim_tree.Config.Renderer
---
---|nvim_tree.Config.HijackDirectories|
---@field hijack_directories? nvim_tree.Config.HijackDirectories
---
---|nvim_tree.Config.UpdateFocusedFile|
---@field update_focused_file? nvim_tree.Config.UpdateFocusedFile
---
---|nvim_tree.Config.SystemOpen|
---@field system_open? nvim_tree.Config.SystemOpen
---
---|nvim_tree.Config.Git|
---@field git? nvim_tree.Config.Git
---
---|nvim_tree.Config.Diagnostics|
---@field diagnostics? nvim_tree.Config.Diagnostics
---
---|nvim_tree.Config.Modified|
---@field modified? nvim_tree.Config.Modified
---
---|nvim_tree.Config.Filters|
---@field filters? nvim_tree.Config.Filters
---
---|nvim_tree.Config.LiveFilter|
---@field live_filter? nvim_tree.Config.LiveFilter
---
---|nvim_tree.Config.FilesystemWatchers|
---@field filesystem_watchers? nvim_tree.Config.FilesystemWatchers
---
---|nvim_tree.Config.Actions|
---@field actions? nvim_tree.Config.Actions
---
---|nvim_tree.Config.Trash|
---@field trash? nvim_tree.Config.Trash
---
---|nvim_tree.Config.Tab|
---@field tab? nvim_tree.Config.Tab
---
---|nvim_tree.Config.Notify|
---@field notify? nvim_tree.Config.Notify
---
---|nvim_tree.Config.Help|
---@field help? nvim_tree.Config.Help
---
---|nvim_tree.Config.UI|
---@field ui? nvim_tree.Config.UI
---
---|nvim_tree.Config.Log|
---@field log? nvim_tree.Config.Log

--
-- HijackDirectories
--

---@class nvim_tree.Config.HijackDirectories
---
---Hijack directory buffers. Disable this option if you use vim-dirvish or dirbuf.nvim. If `hijack_netrw` and `disable_netrw` are `false`, this feature will be disabled.
---(default: `true`)
---@field enable? boolean
---
---Opens the tree if the tree was previously closed.
---(default: `true`)
---@field auto_open? boolean

--
-- Renderer
--

---@class nvim_tree.Config.Renderer
---@field add_trailing? boolean Appends a trailing slash to folder and symlink folder destination names. Default: `false`
---@field group_empty? boolean|fun(relative_path: string): string Compact folders that only contain a single folder into one node. Boolean or function that takes one argument (the relative path of grouped folders) and returns a string to be displayed. Default: `false`
---@field full_name? boolean Display node whose name length is wider than the width of nvim-tree window in floating window. Default: `false`
---@field root_folder_label? string|boolean|fun(root_cwd: string): string In what format to show root folder. See `:help filename-modifiers` for available `string` options. Set to `false` to hide the root folder.  or `boolean` or `function(root_cwd)`, Default: `":~:s?$?/..?"`
---@field indent_width? integer Number of spaces for an each tree nesting level. Minimum 1. Default: `2`
---@field special_files? string[] A list of filenames that gets highlighted with `NvimTreeSpecialFile`. Default: `{ "Cargo.toml", "Makefile", "README.md", "readme.md", }`
---@field hidden_display? fun(hidden_stats: table<string, integer>): string|nil|nvim_tree.HiddenDisplayOption Show a summary of hidden files below the tree using `NvimTreeHiddenDisplay Default: `"none"`
---@field symlink_destination? boolean Whether to show the destination of the symlink. Default: `true`
---@field decorators? (string|nvim_tree.api.decorator.UserDecorator)[] Highlighting and icons for the nodes, in increasing order of precedence. Uses strings to specify builtin decorators otherwise specify your `nvim_tree.api.decorator.UserDecorator` class. Default: > lua { "Git", "Open", "Hidden", "Modified", "Bookmark", "Diagnostics", "Copied", "Cut", }
---@field highlight_git? nvim_tree.HighlightOption Enable highlight for git attributes using `NvimTreeGit*HL` highlight groups. Requires |nvim-tree.git.enable| Value can be `"none"`, `"icon"`, `"name"` or `"all"`. Default: `"none"` @see nvim-tree.git.enable
---@field highlight_diagnostics? nvim_tree.HighlightOption Enable highlight for diagnostics using `NvimTreeDiagnostic*HL` highlight groups. Requires |nvim-tree.diagnostics.enable| Value can be `"none"`, `"icon"`, `"name"` or `"all"`. Default: `"none"` @see nvim-tree.diagnostics.enable
---@field highlight_opened_files? nvim_tree.HighlightOption Highlight icons and/or names for |bufloaded()| files using the `NvimTreeOpenedHL` highlight group. See |nvim-tree-api.navigate.opened.next()| and |nvim-tree-api.navigate.opened.prev()| Value can be `"none"`, `"icon"`, `"name"` or `"all"`. Default: `"none"`
---@field highlight_modified? nvim_tree.HighlightOption Highlight icons and/or names for modified files using the `NvimTreeModifiedFile` highlight group. Requires |nvim-tree.modified.enable| Value can be `"none"`, `"icon"`, `"name"` or `"all"` Default `"none"` @see nvim-tree.modified.enable
---@field highlight_hidden? nvim_tree.HighlightOption Highlight icons and/or names for hidden files (dotfiles) using the `NvimTreeHiddenFileHL` highlight group. Value can be `"none"`, `"icon"`, `"name"` or `"all"` Default `"none"`
---@field highlight_bookmarks? nvim_tree.HighlightOption Highlight bookmarked using the `NvimTreeBookmarkHL` group. Value can be `"none"`, `"icon"`, `"name"` or `"all"` Default `"none"`
---@field highlight_clipboard? nvim_tree.HighlightOption Enable highlight for clipboard items using the `NvimTreeCutHL` and `NvimTreeCopiedHL` groups. Value can be `"none"`, `"icon"`, `"name"` or `"all"`. Default: `"name"`
---@field indent_markers? nvim_tree.Config.Renderer.IndentMarkers Configuration options for tree indent markers.
---@field icons? nvim_tree.Config.Renderer.Icons Configuration options for icons.

---@class nvim_tree.Config.Renderer.IndentMarkers
---@field enable? boolean Display indent markers when folders are open Default: `false`
---@field inline_arrows? boolean Display folder arrows in the same column as indent marker when using |renderer.icons.show.folder_arrow| Default: `true`
---@field icons? nvim_tree.Config.Renderer.IndentMarkers.Icons Icons shown before the file/directory. Length 1. Default: > lua { corner = "└", edge = "│", item = "│", bottom = "─", none = " ", }

---@class nvim_tree.Config.Renderer.IndentMarkers.Icons
---@field corner? string Default: `"└"`
---@field edge? string Default: `"│"`
---@field item? string Default: `"│"`
---@field bottom? string Default: `"─"`
---@field none? string Default: `" "`

---@class nvim_tree.Config.Renderer.Icons Configuration options for icons.
---@field web_devicons? nvim_tree.Config.Renderer.Icons.WebDevicons Configure optional plugin `"nvim-tree/nvim-web-devicons"`
---@field git_placement? nvim_tree.PlacementOption Git icons placement. Default: `"before"`
---@field diagnostics_placement? nvim_tree.PlacementOption Diganostic icon placement. Default: `"signcolumn"` @see nvim-tree.view.signcolumn @see nvim-tree.renderer.icons.show.diagnostics
---@field modified_placement? nvim_tree.PlacementOption Modified icon placement. Default: `"after"`
---@field hidden_placement? nvim_tree.PlacementOption Hidden icon placement. Default: `"after"`
---@field bookmarks_placement? nvim_tree.PlacementOption Bookmark icon placement. Default: `"signcolumn"` @see nvim-tree.renderer.icons.show.bookmarks
---@field padding? nvim_tree.Config.Renderer.Icons.Padding
---@field symlink_arrow? string Used as a separator between symlinks' source and target. Default: `" ➛ "`
---@field show? nvim_tree.Config.Renderer.Icons.Show Configuration options for showing icon types. Left to right order: file/folder, git, modified, hidden, diagnostics, bookmarked.
---@field glyphs? nvim_tree.Config.Renderer.Icons.Glyphs Configuration options for icon glyphs. NOTE: Do not set any glyphs to more than two characters if it's going to appear in the signcolumn.

---@class nvim_tree.Config.Renderer.Icons.WebDevicons
---@field file? nvim_tree.Config.Renderer.Icons.WebDevicons.File File icons.
---@field folder? nvim_tree.Config.Renderer.Icons.WebDevicons.Folder Folder icons.

---@class nvim_tree.Config.Renderer.Icons.WebDevicons.File
---@field enable? boolean Show icons on files. Overrides |nvim-tree.renderer.icons.glyphs.default| Default: `true`
---@field color? boolean Use icon colors for files. Overrides highlight groups. Default: `true`

---@class nvim_tree.Config.Renderer.Icons.WebDevicons.Folder
---@field enable? boolean Show icons on folders. Overrides |nvim-tree.renderer.icons.glyphs.folder| Default: `false`
---@field color? boolean Use icon colors for folders. Overrides highlight groups. Default: `true`

---@class nvim_tree.Config.Renderer.Icons.Padding
---@field icon? string Inserted between icon and filename. Default: `" "`
---@field folder_arrow? string Inserted between folder arrow icon and file/folder icon. Default: `" "`

---@class nvim_tree.Config.Renderer.Icons.Show
---@field file? boolean Show an icon before the file name. Default: `true`
---@field folder? boolean Show an icon before the folder name. Default: `true`
---@field folder_arrow? boolean Show a small arrow before the folder node. Arrow will be a part of the node when using |renderer.indent_markers|. Default: `true`
---@field git? boolean Show a git status icon, see |renderer.icons.git_placement| Requires |git.enable| `= true` Default: `true` @see nvim-tree.renderer.icons.git_placement @see nvim-tree.git.enable
---@field modified? boolean Show a modified icon, see |renderer.icons.modified_placement| Requires |modified.enable| `= true` Default: `true` @see nvim-tree.renderer.icons.modified_placement @see nvim-tree.modified.enable
---@field hidden? boolean Show a hidden icon, see |renderer.icons.hidden_placement| Default: `false` @see nvim-tree.renderer.icons.hidden_placement
---@field diagnostics? boolean Show a diagnostics status icon, see |renderer.icons.diagnostics_placement| Requires |diagnostics.enable| `= true` Default: `true` @see nvim-tree.renderer.icons.diagnostics_placement @see nvim-tree.diagnostics.enable
---@field bookmarks? boolean Show a bookmark icon, see |renderer.icons.bookmarks_placement| Default: `true` @see nvim-tree.renderer.icons.bookmarks_placement

---@class nvim_tree.Config.Renderer.Icons.Glyphs
---@field default? string Glyph for files. Overridden by |nvim-tree.renderer.icons.web_devicons| if available. Default: `""`
---@field symlink? string Glyph for symlinks to files. Default: `""`
---@field bookmark? string Bookmark icon. Default: `"Ὰ4"`
---@field modified? string Icon to display for modified files. Default: `"●"`
---@field hidden? string Icon to display for hidden files. Default: `"c""`
---@field folder? nvim_tree.Config.Renderer.Icons.Glyphs.Folder Glyphs for directories. Overridden by |nvim-tree.renderer.icons.web_devicons| if available. Default: `{ arrow_closed = "", arrow_open = "", default = "", open = "", empty = "", empty_open = "", symlink = "", symlink_open = "", }`
---@field git? nvim_tree.Config.Renderer.Icons.Glyphs.Git Glyphs for git status. Default: `{ unstaged = "✗", staged = "✓", unmerged = "", renamed = "➜", untracked = "★", deleted = "", ignored = "◌", }`

---@class nvim_tree.Config.Renderer.Icons.Glyphs.Folder
---@field arrow_closed? string Default: `""`
---@field arrow_open? string Default: `""`
---@field default? string Default: `""`
---@field open? string Default: `""`
---@field empty? string Default: `""`
---@field empty_open? string Default: `""`
---@field symlink? string Default: `""`
---@field symlink_open? string Default: `""`

---@class nvim_tree.Config.Renderer.Icons.Glyphs.Git
---@field unstaged? string Default: `"✗"`
---@field staged? string Default: `"✓"`
---@field unmerged? string Default: `""`
---@field renamed? string Default: `"➜"`
---@field untracked? string Default: `"★"`
---@field deleted? string Default: `""`
---@field ignored? string Default: `"◌"`

--
-- Modified
--

---@class nvim_tree.Config.Modified
---@field enable? boolean Enable / disable the feature. Default: `false`
---@field show_on_dirs? boolean Show modified indication on directory whose children are modified. Default: `true`
---@field show_on_open_dirs? boolean Show modified indication on open directories. Only relevant when |modified.show_on_dirs| is `true`. Default: `false` @see nvim-tree.modified.show_on_dirs

--
-- Tab
--

---@class nvim_tree.Config.Tab
---@field sync? nvim_tree.Config.Tab.Sync Configuration for syncing nvim-tree across tabs.

---@class nvim_tree.Config.Tab.Sync
---@field open? boolean Opens the tree automatically when switching tabpage or opening a new tabpage if the tree was previously open. Default: `false`
---@field close? boolean Closes the tree across all tabpages when the tree is closed. Default: `false`
---@field ignore? string[] List of filetypes or buffer names on new tab that will prevent |nvim-tree.tab.sync.open| and |nvim-tree.tab.sync.close| Default: `{}`

--
-- Trash
--

---@class nvim_tree.Config.Trash
---@field cmd? string The command used to trash items (must be installed on your system). Default linux `"gio trash"` from glib2 is a commonly shipped linux package. macOS default `"trash"` requires the homebrew package `trash` Windows default `"trash"` requires `trash-cli` or similar Default: `"gio trash"` or `"trash"`

--
-- Live Filter
--

---@class nvim_tree.Config.LiveFilter
---@field prefix? string Prefix of the filter displayed in the buffer. Default: `"[FILTER]: "`
---@field always_show_folders? boolean Whether to filter folders or not. Default: `true`

--
-- System Open
--

---@class nvim_tree.Config.SystemOpen
---@field cmd? string The open command itself. Default: `""` neovim >= 0.10 defaults to |vim.ui.open| neovim < 0.10 defaults to: UNIX: `"xdg-open"` macOS: `"open"` Windows: `"cmd"`
---@field args? string[] Optional argument list. Default: `{}` Leave empty for OS specific default: Windows: `{ "/c", "start", '""' }`

--
-- Help
--

---@class nvim_tree.Config.Help
---@field sort_by? nvim_tree.HelpSortOption Defines how mappings are sorted in the help window. Can be `"key"` (sort alphabetically by keymap) or `"desc"` (sort alphabetically by description). Default: `"key"`

--
-- Sort
--

---@class nvim_tree.Config.Sort
---@field sorter? nvim_tree.SortOption|fun(nodes: table): nil Changes how files within the same directory are sorted. Can be one of `"name"`, `"case_sensitive"`, `"modification_time"`, `"extension"`, `"suffix"`, `"filetype"` or a function. `"extension"` uses all suffixes e.g. `foo.tar.gz` -> `.tar.gz` `"suffix"` uses the last e.g. `.gz` Default: `"name"` Function may perform a sort or return a string with one of the above methods. It is passed a table of nodes to be sorted, each node containing: - `absolute_path`: `string` - `executable`: `boolean` - `extension`: `string` - `filetype`: `string` - `link_to`: `string` - `name`: `string` - `type`: `"directory"` | `"file"` | `"link"`
---@field folders_first? boolean Sort folders before files. Has no effect when |nvim-tree.sort.sorter| is a function. Default: `true` @see nvim-tree.sort.sorter
---@field files_first? boolean Sort files before folders. Has no effect when |nvim-tree.sort.sorter| is a function. If set to `true` it overrides |nvim-tree.sort.folders_first|. Default: `false` @see nvim-tree.sort.sorter @see nvim-tree.sort.folders_first

--
-- Filters
--

---@class nvim_tree.Config.Filters
---@field enable? boolean Enable / disable all filters including live filter. Toggle via |nvim-tree-api.tree.toggle_enable_filters()| Default: `true`
---@field git_ignored? boolean Ignore files based on `.gitignore`. Requires |git.enable| `= true` Toggle via |nvim-tree-api.tree.toggle_gitignore_filter()|, default `I` Default: `true`
---@field dotfiles? boolean Do not show dotfiles: files starting with a `.` Toggle via |nvim-tree-api.tree.toggle_hidden_filter()|, default `H` Default: `false`
---@field git_clean? boolean Do not show files with no git status. This will show ignored files when |nvim-tree.filters.git_ignored| is set, as they are effectively dirty. Toggle via |nvim-tree-api.tree.toggle_git_clean_filter()|, default `C` Default: `false`
---@field no_buffer? boolean Do not show files that have no |buflisted()| buffer. Toggle via |nvim-tree-api.tree.toggle_no_buffer_filter()|, default `B` For performance reasons this may not immediately update on buffer delete/wipe. A reload or filesystem event will result in an update. Default: `false`
---@field no_bookmark? boolean Do not show files that are not bookmarked. Toggle via |nvim-tree-api.tree.toggle_no_bookmark_filter()|, default `M` Enabling this is not useful as there is no means yet to persist bookmarks. Default: `false`
---@field custom? string[]|fun(absolute_path: string): boolean Custom list of vim regex for file/directory names that will not be shown. Backslashes must be escaped e.g. "^\\.git". See |string-match|. Toggle via |nvim-tree-api.tree.toggle_custom_filter()|, default `U` Default: `{}`
---@field exclude? string[] List of directories or files to exclude from filtering: always show them. Overrides `filters.git_ignored`, `filters.dotfiles` and `filters.custom`. Default: `{}`

--
-- Update Focused File
--

---@class nvim_tree.Config.UpdateFocusedFile
---@field enable? boolean Enable this feature. Default: `false`
---@field update_root? nvim_tree.Config.UpdateFocusedFile.UpdateRoot Update the root directory of the tree if the file is not under current root directory. It prefers vim's cwd and `root_dirs`. Otherwise it falls back to the folder containing the file. Only relevant when `update_focused_file.enable` is `true` @see nvim-tree.update_focused_file.enable
---@field exclude? fun(args: vim.api.keyset.create_autocmd.callback_args): boolean A function that returns true if the file should not be focused when opening. Takes the `BufEnter` event as an argument. see |autocmd-events| Default: `false`

---@class nvim_tree.Config.UpdateFocusedFile.UpdateRoot
---@field enable? boolean Default: `false`
---@field ignore_list? string[] List of buffer names and filetypes that will not update the root dir of the tree if the file isn't found under the current root directory. Only relevant when `update_focused_file.update_root.enable` and `update_focused_file.enable` are `true`. Default: `{}` @see nvim-tree.update_focused_file.update_root.enable @see nvim-tree.update_focused_file.enable

--
-- Git
--

---@class nvim_tree.Config.Git
---@field enable? boolean Enable / disable the feature. Default: `true`
---@field show_on_dirs? boolean Show status icons of children when directory itself has no status icon. Default: `true`
---@field show_on_open_dirs? boolean Show status icons of children on directories that are open. Only relevant when `git.show_on_dirs` is `true`. Default: `true` @see nvim-tree.git.show_on_dirs
---@field disable_for_dirs? string[]|fun(path: string): boolean Disable git integration when git top-level matches these paths. Strings may be relative, evaluated via |fnamemodify| `:p` Function is passed an absolute path and returns true for disable. Default: `{}`
---@field timeout? integer Kills the git process after some time if it takes too long. Git integration will be disabled after 10 git jobs exceed this timeout. Default: `400` (ms)
---@field cygwin_support? boolean Use `cygpath` if available to resolve paths for git. Default: `false`

--
-- Diagnostics
--

---@class nvim_tree.Config.Diagnostics
---@field enable? boolean Enable/disable the feature. Default: `false`
---@field debounce_delay? integer Idle milliseconds between diagnostic event and update. Default: `500` (ms)
---@field show_on_dirs? boolean Show diagnostic icons on parent directories. Default: `false`
---@field show_on_open_dirs? boolean Show diagnostics icons on directories that are open. Only relevant when `diagnostics.show_on_dirs` is `true`. Default: `true` @see nvim-tree.diagnostics.show_on_dirs
---@field severity? nvim_tree.Config.Diagnostics.Severity Severity for which the diagnostics will be displayed. See |diagnostic-severity| @see nvim-tree.diagnostics.icons
---@field icons? nvim_tree.Config.Diagnostics.Icons Icons for diagnostic severity.
---@field diagnostic_opts? boolean vim.diagnostic.Opts overrides nvim-tree.diagnostics.severity and nvim-tree.diagnostics.icons Default: `false`

---@class nvim_tree.Config.Diagnostics.Severity
---@field min? vim.diagnostic.Severity Minimum severity. Default: `vim.diagnostic.severity.HINT`
---@field max? vim.diagnostic.Severity Maximum severity. Default: `vim.diagnostic.severity.ERROR`

---@class nvim_tree.Config.Diagnostics.Icons
---@field hint? string Default: `""`
---@field info? string Default: `""`
---@field warning? string Default: `""`
---@field error? string Default: `""`

--
-- Notify
--

---@class nvim_tree.Config.Notify
---@field threshold? vim.log.levels Specify minimum notification level, uses the values from |vim.log.levels| Default: `vim.log.levels.INFO` `ERROR`: hard errors e.g. failure to read from the file system. `WARNING`: non-fatal errors e.g. unable to system open a file. `INFO:` information only e.g. file copy path confirmation. `DEBUG:` information for troubleshooting, e.g. failures in some window closing operations.
---@field absolute_path? boolean Whether to use absolute paths or item names in fs action notifications. Default: `true`

--
-- Filesystem Watchers
--

---@class nvim_tree.Config.FilesystemWatchers
---@field enable? boolean Enable / disable the feature. Default: `true`
---@field debounce_delay? integer Idle milliseconds between filesystem change and action. Default: `50` (ms)
---@field ignore_dirs? string[]|fun(path: string): boolean List of vim regex for absolute directory paths that will not be watched or function returning whether a path should be ignored. Strings must be backslash escaped e.g. `"my-proj/\\.build$"`. See |string-match|. Function is passed an absolute path. Useful when path is not in `.gitignore` or git integration is disabled. Default: `{ "/.ccls-cache", "/build", "/node_modules", "/target", }`

--
-- Log
--

---@class nvim_tree.Config.Log
---@field enable? boolean Enable logging to a file `nvim-tree.log` in |stdpath| `"log"`, usually `${XDG_STATE_HOME}/nvim` Default: `false`
---@field truncate? boolean Remove existing log file at startup. Default: `false`
---@field types? nvim_tree.Config.Log.Types Specify which information to log.

---@class nvim_tree.Config.Log.Types
---@field all? boolean Everything. Default: `false`
---@field profile? boolean Timing of some operations. Default: `false`
---@field config? boolean Options and mappings, at startup. Default: `false`
---@field copy_paste? boolean File copy and paste actions. Default: `false`
---@field dev? boolean Used for local development only. Not useful for users. Default: `false`
---@field diagnostics? boolean LSP and COC processing, verbose. Default: `false`
---@field git? boolean Git processing, verbose. Default: `false`
---@field watcher? boolean nvim-tree.filesystem_watchers processing, verbose. Default: `false`

--
-- UI
--

---@class nvim_tree.Config.UI
---
---|nvim_tree.Config.UI.Confirm|
---@field confirm? nvim_tree.Config.UI.Confirm

--
-- UI.Confirm
--

---Confirmation prompts.
---@class nvim_tree.Config.UI.Confirm
---
---Prompt before removing.
---(default: `true`)
---@field remove? boolean
---
---Prompt before trashing.
---(default: `true`)
---@field trash? boolean
---
---If `true` the prompt will be `Y/n`, otherwise `y/N`
---(default: `false`)
---@field default_yes? boolean

--
-- Actions
--

---@class nvim_tree.Config.Actions
---
---A boolean value that toggle the use of system clipboard when copy/paste function are invoked. When enabled, copied text will be stored in registers `+` (system), otherwise, it will be stored in `1` and `"`
---(default: `true`)
---@field use_system_clipboard? boolean
---
---|nvim_tree.Config.Actions.ChangeDir|
---@field change_dir? nvim_tree.Config.Actions.ChangeDir
---
---|nvim_tree.Config.Actions.ExpandAll|
---@field expand_all? nvim_tree.Config.Actions.ExpandAll
---
---|nvim_tree.Config.Actions.FilePopup|
---@field file_popup? nvim_tree.Config.Actions.FilePopup
---
---|nvim_tree.Config.Actions.OpenFile|
---@field open_file? nvim_tree.Config.Actions.OpenFile
---
---|nvim_tree.Config.Actions.RemoveFile|
---@field remove_file? nvim_tree.Config.Actions.RemoveFile

--
-- Actions.ChangeDir
--

--- vim |current-directory| behaviour
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

--
-- Actions.ExpandAll
--

---Configuration for |nvim-tree-api.tree.expand_all()| and |nvim-tree-api.node.expand()|
---@class nvim_tree.Config.Actions.ExpandAll
---
---Limit the number of folders being explored when expanding every folders. Avoids hanging neovim when running this action on very large folders.
---(default: `300`)
---@field max_folder_discovery? integer
---
---A list of directories that should not be expanded automatically e.g `{ ".git", "target", "build" }`
---(default: `{}`)
---@field exclude? string[]

--
-- Actions.FilePopup
--

---Configuration for file_popup behaviour.
---@class nvim_tree.Config.Actions.FilePopup
---
---Floating window config for file_popup. See |nvim_open_win| and |vim.api.keyset.win_config| for more details. You shouldn't define `width` and `height` values here. They will be overridden to fit the file_popup content.
---(default: `{ col = 1, row = 1, relative = "cursor", border = "shadow", style = "minimal", }`)
---@field open_win_config? vim.api.keyset.win_config

--
-- Actions.OpenFile
--

---Configuration options for opening a file from nvim-tree.
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
---|nvim_tree.Config.Actions.OpenFile.WindowPicker|
---@field window_picker? nvim_tree.Config.Actions.OpenFile.WindowPicker

--
-- Actions.OpenFile.WindowPicker
--

---Window picker configuration.
---@class nvim_tree.Config.Actions.OpenFile.WindowPicker
---
---Enable the feature. If the feature is not enabled, files will open in window from which you last opened the tree, obeying |nvim-tree.actions.open_file.window_picker.exclude|
---(default: `true`)
---@field enable? boolean
---
---Change the default window picker: a string `"default"` or a function. The function should return the window id that will open the node, or `nil` if an invalid window is picked or user cancelled the action. The picker may create a new window.
---(default: `"default"`)
---@field picker? string|fun(): integer
---
---A string of chars used as identifiers by the window picker.
---(default: `"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"`)
---@field chars? string
---
---|nvim_tree.Config.Actions.OpenFile.WindowPicker.Exclude|
---@field exclude? nvim_tree.Config.Actions.OpenFile.WindowPicker.Exclude

--
-- Actions.OpenFile.WindowPicker.Exclude
--

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

--
-- Actions.RemoveFile
--

---Configuration options for removing a file from nvim-tree.
---@class nvim_tree.Config.Actions.RemoveFile
---
---Close any window that displays a file when removing that file from the tree.
---(default: `true`)
---@field close_window? boolean

--
-- View
--

---@class nvim_tree.Config.View
---@field adaptive_size? boolean Resize the window on each draw based on the longest line. Default: `false`
---@field centralize_selection? boolean When entering nvim-tree, reposition the view so that the current node is initially centralized, see |zz|. Default: `false`
---@field side? nvim_tree.PlacementOption Side of the tree. Default: `"left"`
---@field preserve_window_proportions? boolean Preserves window proportions when opening a file. If `false`, the height and width of windows other than nvim-tree will be equalized. Default: `false`
---@field number? boolean Print the line number in front of each line. Default: `false`
---@field relativenumber? boolean Show the line number relative to the line with the cursor in front of each line. Default: `false`
---@field signcolumn? nvim_tree.HiddenDisplayOption Show |signcolumn|. Default: `"yes"`
---@field width? string|integer|nvim_tree.Config.View.Width|fun(): integer|string Width of the window: can be a `%` string, a number representing columns, a function or a table. A table indicates that the view should be dynamically sized based on the longest line. Default: `30`
---@field float? nvim_tree.Config.View.Float Configuration options for floating window.
---@field cursorline? boolean Enable |cursorline| in nvim-tree window. Default: `true`
---@field debounce_delay? integer Idle milliseconds before some reload / refresh operations. Increase if you experience performance issues around screen refresh. Default: `15` (ms)

---@class nvim_tree.Config.View.Width
---@field min? string|integer|fun(): integer|string Minimum dynamic width. Default: `30`
---@field max? string|integer|fun(): integer|string Maximum dynamic width, -1 for unbounded. Default: `-1`
---@field lines_excluded? string[] Exclude these lines when computing width. Supported values: `"root"`. Default: `{ "root" }`
---@field padding? integer|fun(): integer|string Extra padding to the right. Default: `1`

---@class nvim_tree.Config.View.Float
---@field enable? boolean If true, tree window will be floating. Default: `false`
---@field quit_on_focus_loss? boolean Close the floating tree window when it loses focus. Default: `true`
---@field open_win_config? table|fun(): table Floating window config. See |nvim_open_win()| for more details. Default: `{ relative = "editor", border = "rounded", width = 30, height = 30, row = 1, col = 1, }`
