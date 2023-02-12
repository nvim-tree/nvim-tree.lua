local api = require "nvim-tree.api"

local M = {}

-- stylua: ignore start
function M.default_on_attach(bufnr)
  -- BEGIN_DEFAULT_ON_ATTACH
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
  vim.keymap.set('n', 'B',     api.tree.toggle_no_buffer_filter,      { desc = 'Toggle No Buffer',       buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'c',     api.fs.copy.node,                      { desc = 'Copy',                   buffer = bufnr, noremap = true, silent = true, nowait = true })
  vim.keymap.set('n', 'C',     api.tree.toggle_git_clean_filter,      { desc = 'Toggle Git Clean',       buffer = bufnr, noremap = true, silent = true, nowait = true })
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
  -- END_DEFAULT_ON_ATTACH
end
-- stylua: ignore end

function M.setup(opts)
  if type(opts.on_attach) ~= "function" then
    M.on_attach = M.default_on_attach
  else
    M.on_attach = opts.on_attach
  end
end

return M
