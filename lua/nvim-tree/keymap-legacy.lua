local api = require "nvim-tree.api"
local open_file = require "nvim-tree.actions.node.open-file"
local keymap = require "nvim-tree.keymap"

local M = {
  user_on_attach_lua = "",
}

local DEFAULT_ON_ATTACH = [[
local api = require('nvim-tree.api')

local on_attach = function(bufnr)

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
]]

-- stylua: ignore start
local LEGACY_MAPPINGS = {
  edit = { key = { "<CR>", "o", "<2-LeftMouse>" }, desc = "Open", fn = api.node.open.edit, n = "api.node.open.edit" },
  edit_in_place = { key = "<C-e>", desc = "Open: In Place", fn = api.node.open.replace_tree_buffer, n = "api.node.open.replace_tree_buffer" },
  edit_no_picker = { key = "O", desc = "Open: No Window Picker", fn = api.node.open.no_window_picker, n = "api.node.open.no_window_picker" },
  cd = { key = { "<C-]>", "<2-RightMouse>" }, desc = "CD", fn = api.tree.change_root_to_node, n = "api.tree.change_root_to_node" },
  vsplit = { key = "<C-v>", desc = "Open: Vertical Split", fn = api.node.open.vertical, n = "api.node.open.vertical" },
  split = { key = "<C-x>", desc = "Open: Horizontal Split", fn = api.node.open.horizontal, n = "api.node.open.horizontal" },
  tabnew = { key = "<C-t>", desc = "Open: New Tab", fn = api.node.open.tab, n = "api.node.open.tab" },
  prev_sibling = { key = "<", desc = "Previous Sibling", fn = api.node.navigate.sibling.prev, n = "api.node.navigate.sibling.prev" },
  next_sibling = { key = ">", desc = "Next Sibling", fn = api.node.navigate.sibling.next, n = "api.node.navigate.sibling.next" },
  parent_node = { key = "P", desc = "Parent Directory", fn = api.node.navigate.parent, n = "api.node.navigate.parent" },
  close_node = { key = "<BS>", desc = "Close Directory", fn = api.node.navigate.parent_close, n = "api.node.navigate.parent_close" },
  preview = { key = "<Tab>", desc = "Open Preview", fn = api.node.open.preview, n = "api.node.open.preview" },
  first_sibling = { key = "K", desc = "First Sibling", fn = api.node.navigate.sibling.first, n = "api.node.navigate.sibling.first" },
  last_sibling = { key = "J", desc = "Last Sibling", fn = api.node.navigate.sibling.last, n = "api.node.navigate.sibling.last" },
  toggle_git_ignored = { key = "I", desc = "Toggle Git Ignore", fn = api.tree.toggle_gitignore_filter, n = "api.tree.toggle_gitignore_filter" },
  toggle_no_buffer = { key = "B", desc = "Toggle No Buffer", fn = api.tree.toggle_no_buffer_filter, n = "api.tree.toggle_no_buffer_filter" },
  toggle_git_clean = { key = "C", desc = "Toggle Git Clean", fn = api.tree.toggle_git_clean_filter, n = "api.tree.toggle_git_clean_filter" },
  toggle_dotfiles = { key = "H", desc = "Toggle Dotfiles", fn = api.tree.toggle_hidden_filter, n = "api.tree.toggle_hidden_filter" },
  toggle_custom = { key = "U", desc = "Toggle Hidden", fn = api.tree.toggle_custom_filter, n = "api.tree.toggle_custom_filter" },
  refresh = { key = "R", desc = "Refresh", fn = api.tree.reload, n = "api.tree.reload" },
  create = { key = "a", desc = "Create", fn = api.fs.create, n = "api.fs.create" },
  remove = { key = "d", desc = "Delete", fn = api.fs.remove, n = "api.fs.remove" },
  trash = { key = "D", desc = "Trash", fn = api.fs.trash, n = "api.fs.trash" },
  rename = { key = "r", desc = "Rename", fn = api.fs.rename, n = "api.fs.rename" },
  full_rename = { key = "<C-r>", desc = "Rename: Omit Filename", fn = api.fs.rename_sub, n = "api.fs.rename_sub" },
  rename_basename = { key = "e", desc = "Rename: Basename", fn = api.fs.rename_basename, n = "api.fs.rename_basename" },
  cut = { key = "x", desc = "Cut", fn = api.fs.cut, n = "api.fs.cut" },
  copy = { key = "c", desc = "Copy", fn = api.fs.copy.node, n = "api.fs.copy.node" },
  paste = { key = "p", desc = "Paste", fn = api.fs.paste, n = "api.fs.paste" },
  copy_name = { key = "y", desc = "Copy Name", fn = api.fs.copy.filename, n = "api.fs.copy.filename" },
  copy_path = { key = "Y", desc = "Copy Relative Path", fn = api.fs.copy.relative_path, n = "api.fs.copy.relative_path" },
  copy_absolute_path = { key = "gy", desc = "Copy Absolute Path", fn = api.fs.copy.absolute_path, n = "api.fs.copy.absolute_path" },
  next_diag_item = { key = "]e", desc = "Next Diagnostic", fn = api.node.navigate.diagnostics.next, n = "api.node.navigate.diagnostics.next" },
  next_git_item = { key = "]c", desc = "Next Git", fn = api.node.navigate.git.next, n = "api.node.navigate.git.next" },
  prev_diag_item = { key = "[e", desc = "Prev Diagnostic", fn = api.node.navigate.diagnostics.prev, n = "api.node.navigate.diagnostics.prev" },
  prev_git_item = { key = "[c", desc = "Prev Git", fn = api.node.navigate.git.prev, n = "api.node.navigate.git.prev" },
  dir_up = { key = "-", desc = "Up", fn = api.tree.change_root_to_parent, n = "api.tree.change_root_to_parent" },
  system_open = { key = "s", desc = "Run System", fn = api.node.run.system, n = "api.node.run.system" },
  live_filter = { key = "f", desc = "Filter", fn = api.live_filter.start, n = "api.live_filter.start" },
  clear_live_filter = { key = "F", desc = "Clean Filter", fn = api.live_filter.clear, n = "api.live_filter.clear" },
  close = { key = "q", desc = "Close", fn = api.tree.close, n = "api.tree.close" },
  collapse_all = { key = "W", desc = "Collapse", fn = api.tree.collapse_all, n = "api.tree.collapse_all" },
  expand_all = { key = "E", desc = "Expand All", fn = api.tree.expand_all, n = "api.tree.expand_all" },
  search_node = { key = "S", desc = "Search", fn = api.tree.search_node, n = "api.tree.search_node" },
  run_file_command = { key = ".", desc = "Run Command", fn = api.node.run.cmd, n = "api.node.run.cmd" },
  toggle_file_info = { key = "<C-k>", desc = "Info", fn = api.node.show_info_popup, n = "api.node.show_info_popup" },
  toggle_help = { key = "g?", desc = "Help", fn = api.tree.toggle_help, n = "api.tree.toggle_help" },
  toggle_mark = { key = "m", desc = "Toggle Bookmark", fn = api.marks.toggle, n = "api.marks.toggle" },
  bulk_move = { key = "bmv", desc = "Move Bookmarked", fn = api.marks.bulk.move, n = "api.marks.bulk.move" },
}
-- stylua: ignore end

local function generate_on_attach_function(list, remove_keys, remove_defaults)
  return function(bufnr)
    -- apply defaults first
    if not remove_defaults then
      keymap.default_on_attach(bufnr)
    end

    -- explicit removals
    for _, key in ipairs(remove_keys) do
      vim.keymap.set("n", key, "", { buffer = bufnr })
      vim.keymap.del("n", key, { buffer = bufnr })
    end

    -- mappings
    for _, m in ipairs(list) do
      local keys = type(m.key) == "table" and m.key or { m.key }
      for _, k in ipairs(keys) do
        if LEGACY_MAPPINGS[m.action] then
          -- straight action
          vim.keymap.set(
            m.mode or "n",
            k,
            LEGACY_MAPPINGS[m.action].fn,
            { desc = m.action, buffer = bufnr, noremap = true, silent = true, nowait = true }
          )
        elseif type(m.action_cb) == "function" then
          -- action_cb
          vim.keymap.set(m.mode or "n", k, function()
            m.action_cb(api.tree.get_node_under_cursor())
          end, { desc = m.action, buffer = bufnr, noremap = true, silent = true, nowait = true })
        end
      end
    end
  end
end

local function generate_on_attach_lua(list, remove_keys)
  local lua = ""

  -- explicit removals
  if #remove_keys > 0 then
    lua = lua .. "\n  -- remove_keys\n"
  end
  for _, key in ipairs(remove_keys) do
    lua = lua .. string.format([[  vim.keymap.set('n', '%s', '', { buffer = bufnr })]], key) .. "\n"
    lua = lua .. string.format([[  vim.keymap.del('n', '%s', { buffer = bufnr })]], key) .. "\n"
  end

  -- list
  if #list > 0 then
    lua = lua .. "\n  -- view.mappings.list\n"
  end
  for _, m in ipairs(list) do
    local keys = type(m.key) == "table" and m.key or { m.key }
    for _, k in ipairs(keys) do
      if LEGACY_MAPPINGS[m.action] then
        lua = lua
          .. string.format(
            [[  vim.keymap.set('%s', '%s', %s, { desc = '%s', buffer = bufnr, noremap = true, silent = true, nowait = true })]],
            m.mode or "n",
            k,
            LEGACY_MAPPINGS[m.action].n,
            LEGACY_MAPPINGS[m.action].desc
          )
          .. "\n"
      elseif type(m.action_cb) == "function" then
        lua = lua .. string.format([[  vim.keymap.set('%s', '%s', function()]], m.mode or "n", k) .. "\n"
        lua = lua .. [[    local node = api.tree.get_node_under_cursor()]] .. "\n"
        lua = lua .. [[    -- your code goes here]] .. "\n"
        lua = lua
          .. string.format(
            [[  end, { desc = '%s', buffer = bufnr, noremap = true, silent = true, nowait = true })]],
            m.action
          )
          .. "\n"
      end
    end
  end

  return lua
end

function M.generate_legacy_on_attach(opts)
  if type(opts.on_attach) == "function" then
    return
  end

  local list = opts.view and opts.view.mappings and opts.view.mappings.list or {}
  local remove_keys = type(opts.remove_keymaps) == "table" and opts.remove_keymaps or {}
  local remove_defaults = opts.remove_keymaps == true
    or opts.view and opts.view.mappings and opts.view.mappings.custom_only

  -- do nothing unless the user has configured something
  if #list == 0 and #remove_keys == 0 and not remove_defaults then
    return
  end

  opts.on_attach = generate_on_attach_function(list, remove_keys, remove_defaults)
  M.user_on_attach_lua = generate_on_attach_lua(list, remove_keys)
end

function M.generate_on_attach()
  local name = "/tmp/my_on_attach.lua"
  local file = io.output(name)
  io.write(DEFAULT_ON_ATTACH)
  io.write(M.user_on_attach_lua)
  io.write "end"
  io.close(file)
  open_file.fn("edit", name)
end

return M
