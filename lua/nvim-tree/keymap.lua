local api = require "nvim-tree.api"

local M = {}

-- BEGIN_DEFAULT_KEYMAPS
local DEFAULT_KEYMAPS = {
  {
    key = { "<CR>", "o", "<2-LeftMouse>" },
    callback = api.node.open.edit,
    desc = {
      long = "Open a file or directory; root will cd to the above directory.",
      short = "Open",
    },
    legacy_action = "edit",
  },
  {
    key = "<C-e>",
    callback = api.node.open.replace_tree_buffer,
    desc = {
      long = "Open file in place, effectively replacing the tree explorer.",
      short = "Open: In Place",
    },
    legacy_action = "edit_in_place",
  },
  {
    key = "O",
    callback = api.node.open.no_window_picker,
    desc = {
      long = "Open file with no window picker.",
      short = "Open: No Window Picker",
    },
    legacy_action = "edit_no_picker",
  },
  {
    key = { "<C-]>", "<2-RightMouse>" },
    callback = api.tree.change_root_to_node,
    desc = {
      long = "cd in the directory under the cursor.",
      short = "CD",
    },
    legacy_action = "cd",
  },
  {
    key = "<C-v>",
    callback = api.node.open.vertical,
    desc = {
      long = "Open file in a vertical split.",
      short = "Open: Vertical Split",
    },
    legacy_action = "vsplit",
  },
  {
    key = "<C-x>",
    callback = api.node.open.horizontal,
    desc = {
      long = "Open file in a horizontal split.",
      short = "Open: Horizontal Split",
    },
    legacy_action = "split",
  },
  {
    key = "<C-t>",
    callback = api.node.open.tab,
    desc = {
      long = "Open file in a new tab.",
      short = "Open: New Tab",
    },
    legacy_action = "tabnew",
  },
  {
    key = "<",
    callback = api.node.navigate.sibling.prev,
    desc = {
      long = "Navigate to the previous sibling.",
      short = "Previous Sibling",
    },
    legacy_action = "prev_sibling",
  },
  {
    key = ">",
    callback = api.node.navigate.sibling.next,
    desc = {
      long = "Navigate to the next sibling",
      short = "Next Sibling",
    },
    legacy_action = "next_sibling",
  },
  {
    key = "P",
    callback = api.node.navigate.parent,
    desc = {
      long = "Move cursor to the parent directory.",
      short = "Parent Directory",
    },
    legacy_action = "parent_node",
  },
  {
    key = "<BS>",
    callback = api.node.navigate.parent_close,
    desc = {
      long = "Close current opened directory or parent.",
      short = "Close Directory",
    },
    legacy_action = "close_node",
  },
  {
    key = "<Tab>",
    callback = api.node.open.preview,
    desc = {
      long = "Open file as a preview (keeps the cursor in the tree).",
      short = "Open Preview",
    },
    legacy_action = "preview",
  },
  {
    key = "K",
    callback = api.node.navigate.sibling.first,
    desc = {
      long = "Navigate to the first sibling.",
      short = "First Sibling",
    },
    legacy_action = "first_sibling",
  },
  {
    key = "J",
    callback = api.node.navigate.sibling.last,
    desc = {
      long = "Navigate to the last sibling.",
      short = "Last Sibling",
    },
    legacy_action = "last_sibling",
  },
  {
    key = "I",
    callback = api.tree.toggle_gitignore_filter,
    desc = {
      long = "Toggle visibility of files/directories hidden via |git.ignore| option.",
      short = "Toggle Git Ignore",
    },
    legacy_action = "toggle_git_ignored",
  },
  {
    key = "H",
    callback = api.tree.toggle_hidden_filter,
    desc = {
      long = "Toggle visibility of dotfiles via |filters.dotfiles| option.",
      short = "Toggle Dotfiles",
    },
    legacy_action = "toggle_dotfiles",
  },
  {
    key = "U",
    callback = api.tree.toggle_custom_filter,
    desc = {
      long = "Toggle visibility of files/directories hidden via |filters.custom| option.",
      short = "Toggle Hidden",
    },
    legacy_action = "toggle_custom",
  },
  {
    key = "R",
    callback = api.tree.reload,
    desc = {
      long = "Refresh the tree.",
      short = "Refresh",
    },
    legacy_action = "refresh",
  },
  {
    key = "a",
    callback = api.fs.create,
    desc = {
      long = "Create a file; leaving a trailing `/` will add a directory.",
      short = "Create",
    },
    legacy_action = "create",
  },
  {
    key = "d",
    callback = api.fs.remove,
    desc = {
      long = "Delete a file, prompting for confirmation.",
      short = "Delete",
    },
    legacy_action = "remove",
  },
  {
    key = "D",
    callback = api.fs.trash,
    desc = {
      long = "Trash a file via |trash| option.",
      short = "Trash",
    },
    legacy_action = "trash",
  },
  {
    key = "r",
    callback = api.fs.rename,
    desc = {
      long = "Rename a file or directory.",
      short = "Rename",
    },
    legacy_action = "rename",
  },
  {
    key = "<C-r>",
    callback = api.fs.rename_sub,
    desc = {
      long = "Rename a file or directory and omit the filename on input.",
      short = "Rename: Omit Filename",
    },
    legacy_action = "full_rename",
  },
  {
    key = "e",
    callback = api.fs.rename_basename,
    desc = {
      long = "no description",
      short = "Rename: Basename",
    },
    legacy_action = "rename_basename",
  },
  {
    key = "x",
    callback = api.fs.cut,
    desc = {
      long = "Cut file or directory to cut clipboard.",
      short = "Cut",
    },
    legacy_action = "cut",
  },
  {
    key = "c",
    callback = api.fs.copy.node,
    desc = {
      long = "Copy file or directory to copy clipboard.",
      short = "Copy",
    },
    legacy_action = "copy",
  },
  {
    key = "p",
    callback = api.fs.paste,
    desc = {
      long = "Paste from clipboard; cut clipboard has precedence over copy; will prompt for confirmation.",
      short = "Paste",
    },
    legacy_action = "paste",
  },
  {
    key = "y",
    callback = api.fs.copy.filename,
    desc = {
      long = "Copy name to system clipboard.",
      short = "Copy Name",
    },
    legacy_action = "copy_name",
  },
  {
    key = "Y",
    callback = api.fs.copy.relative_path,
    desc = {
      long = "Copy relative path to system clipboard.",
      short = "Copy Relative Path",
    },
    legacy_action = "copy_path",
  },
  {
    key = "gy",
    callback = api.fs.copy.absolute_path,
    desc = {
      long = "Copy absolute path to system clipboard.",
      short = "Copy Absolute Path",
    },
    legacy_action = "copy_absolute_path",
  },
  {
    key = "]e",
    callback = api.node.navigate.diagnostics.next,
    desc = {
      long = "Go to next diagnostic item.",
      short = "Next Diagnostic",
    },
    legacy_action = "next_diag_item",
  },
  {
    key = "]c",
    callback = api.node.navigate.git.next,
    desc = {
      long = "Go to next git item.",
      short = "Next Git",
    },
    legacy_action = "next_git_item",
  },
  {
    key = "[e",
    callback = api.node.navigate.diagnostics.prev,
    desc = {
      long = "Go to prev diagnostic item.",
      short = "Prev Diagnostic",
    },
    legacy_action = "prev_diag_item",
  },
  {
    key = "[c",
    callback = api.node.navigate.git.prev,
    desc = {
      long = "Go to prev git item.",
      short = "Prev Git",
    },
    legacy_action = "prev_git_item",
  },
  {
    key = "-",
    callback = api.tree.change_root_to_parent,
    desc = {
      long = "Navigate up to the parent directory of the current file/directory.",
      short = "Up",
    },
    legacy_action = "dir_up",
  },
  {
    key = "s",
    callback = api.node.run.system,
    desc = {
      long = "Open a file with default system application or a directory with default file manager, using |system_open| option.",
      short = "Run System",
    },
    legacy_action = "system_open",
  },
  {
    key = "f",
    callback = api.live_filter.start,
    desc = {
      long = "Live filter nodes dynamically based on regex matching.",
      short = "Filter",
    },
    legacy_action = "live_filter",
  },
  {
    key = "F",
    callback = api.live_filter.clear,
    desc = {
      long = "Clear live filter.",
      short = "Clean Filter",
    },
    legacy_action = "clear_live_filter",
  },
  {
    key = "q",
    callback = api.tree.close,
    desc = {
      long = "Close tree window.",
      short = "Close",
    },
    legacy_action = "close",
  },
  {
    key = "W",
    callback = api.tree.collapse_all,
    desc = {
      long = "Collapse the whole tree.",
      short = "Collapse",
    },
    legacy_action = "collapse_all",
  },
  {
    key = "E",
    callback = api.tree.expand_all,
    desc = {
      long = "Expand the whole tree, stopping after expanding |callbacks.expand_all.max_folder_discovery| directories; this might hang neovim for a while if running on a big directory.",
      short = "Expand All",
    },
    legacy_action = "expand_all",
  },
  {
    key = "S",
    callback = api.tree.search_node,
    desc = {
      long = "Prompt the user to enter a path and then expands the tree to match the path.",
      short = "Search",
    },
    legacy_action = "search_node",
  },
  {
    key = ".",
    callback = api.node.run.cmd,
    desc = {
      long = "Enter vim command mode with the file the cursor is on.",
      short = "Run Command",
    },
    legacy_action = "run_file_command",
  },
  {
    key = "<C-k>",
    callback = api.node.show_info_popup,
    desc = {
      long = "Toggle a popup with file info about the file under the cursor.",
      short = "Info",
    },
    legacy_action = "toggle_file_info",
  },
  {
    key = "g?",
    callback = api.tree.toggle_help,
    desc = {
      long = "Toggle help.",
      short = "Help",
    },
    legacy_action = "toggle_help",
  },
  {
    key = "m",
    callback = api.marks.toggle,
    desc = {
      long = "Toggle node in bookmarks.",
      short = "Toggle Bookmark",
    },
    legacy_action = "toggle_mark",
  },
  {
    key = "bmv",
    callback = api.marks.bulk.move,
    desc = {
      long = "Move all bookmarked nodes into specified location.",
      short = "Move Bookmarked",
    },
    legacy_action = "bulk_move",
  },
}
-- END_DEFAULT_KEYMAPS

-- stylua: ignore start
function M.on_attach_default(bufnr)
  vim.keymap.set('n', '<C-]>', api.tree.change_root_to_node,          { desc = 'CD',                     buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<C-e>', api.node.open.replace_tree_buffer,     { desc = 'Open: In Place',         buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<C-k>', api.node.show_info_popup,              { desc = 'Info',                   buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<C-r>', api.fs.rename_sub,                     { desc = 'Rename: Omit Filename',  buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<C-t>', api.node.open.tab,                     { desc = 'Open: New Tab',          buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<C-v>', api.node.open.vertical,                { desc = 'Open: Vertical Split',   buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<C-x>', api.node.open.horizontal,              { desc = 'Open: Horizontal Split', buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<BS>',  api.node.navigate.parent_close,        { desc = 'Close Directory',        buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<CR>',  api.node.open.edit,                    { desc = 'Open',                   buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<Tab>', api.node.open.preview,                 { desc = 'Open Preview',           buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '>',     api.node.navigate.sibling.next,        { desc = 'Next Sibling',           buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<',     api.node.navigate.sibling.prev,        { desc = 'Previous Sibling',       buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '.',     api.node.run.cmd,                      { desc = 'Run Command',            buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '-',     api.tree.change_root_to_parent,        { desc = 'Up',                     buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'a',     api.fs.create,                         { desc = 'Create',                 buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'bmv',   api.marks.bulk.move,                   { desc = 'Move Bookmarked',        buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'c',     api.fs.copy.node,                      { desc = 'Copy',                   buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '[c',    api.node.navigate.git.prev,            { desc = 'Prev Git',               buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', ']c',    api.node.navigate.git.next,            { desc = 'Next Git',               buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'd',     api.fs.remove,                         { desc = 'Delete',                 buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'D',     api.fs.trash,                          { desc = 'Trash',                  buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'E',     api.tree.expand_all,                   { desc = 'Expand All',             buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'e',     api.fs.rename_basename,                { desc = 'Rename: Basename',       buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', ']e',    api.node.navigate.diagnostics.next,    { desc = 'Next Diagnostic',        buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '[e',    api.node.navigate.diagnostics.prev,    { desc = 'Prev Diagnostic',        buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'F',     api.live_filter.clear,                 { desc = 'Clean Filter',           buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'f',     api.live_filter.start,                 { desc = 'Filter',                 buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'g?',    api.tree.toggle_help,                  { desc = 'Help',                   buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'gy',    api.fs.copy.absolute_path,             { desc = 'Copy Absolute Path',     buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'H',     api.tree.toggle_hidden_filter,         { desc = 'Toggle Dotfiles',        buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'I',     api.tree.toggle_gitignore_filter,      { desc = 'Toggle Git Ignore',      buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'J',     api.node.navigate.sibling.last,        { desc = 'Last Sibling',           buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'K',     api.node.navigate.sibling.first,       { desc = 'First Sibling',          buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'm',     api.marks.toggle,                      { desc = 'Toggle Bookmark',        buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'o',     api.node.open.edit,                    { desc = 'Open',                   buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'O',     api.node.open.no_window_picker,        { desc = 'Open: No Window Picker', buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'p',     api.fs.paste,                          { desc = 'Paste',                  buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'P',     api.node.navigate.parent,              { desc = 'Parent Directory',       buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'q',     api.tree.close,                        { desc = 'Close',                  buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'r',     api.fs.rename,                         { desc = 'Rename',                 buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'R',     api.tree.reload,                       { desc = 'Refresh',                buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 's',     api.node.run.system,                   { desc = 'Run System',             buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'S',     api.tree.search_node,                  { desc = 'Search',                 buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'U',     api.tree.toggle_custom_filter,         { desc = 'Toggle Hidden',          buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'W',     api.tree.collapse_all,                 { desc = 'Collapse',               buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'x',     api.fs.cut,                            { desc = 'Cut',                    buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'y',     api.fs.copy.filename,                  { desc = 'Copy Name',              buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'Y',     api.fs.copy.relative_path,             { desc = 'Copy Relative Path',     buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<2-LeftMouse>',  api.node.open.edit,           { desc = 'Open',                   buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, { desc = 'CD',                     buffer = bufnr, noremap = true, silent = true, nowait = true })
end
-- stylua: ignore end

function M.setup(opts)
  if type(opts.on_attach) ~= "function" then
    M.on_attach = M.on_attach_default
  else
    M.on_attach = opts.on_attach
  end
end

M.DEFAULT_KEYMAPS = DEFAULT_KEYMAPS

return M
