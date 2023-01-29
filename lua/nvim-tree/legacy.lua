local api = require "nvim-tree.api"
local utils = require "nvim-tree.utils"
local notify = require "nvim-tree.notify"
local open_file = require "nvim-tree.actions.node.open-file"
local keymap = require "nvim-tree.keymap"

local M = {
  on_attach_lua = "",
}

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
  toggle_dotfiles = { key = "H", desc = "Toggle Dotfiles", fn = api.tree.toggle_hidden_filter, n = "api.tree.toggle_hidden_filter" },
  toggle_custom = { key = "U", desc = "Toggle Hidden", fn = api.tree.toggle_custom_filter, n = "api.tree.toggle_custom_filter" },
  refresh = { key = "R", desc = "Refresh", fn = api.tree.reload, n = "api.tree.reload" },
  create = { key = "a", desc = "Create", fn = api.fs.create, n = "api.fs.create" },
  remove = { key = "d", desc = "Delete", fn = api.fs.remove, n = "api.fs.remove" },
  trash = { key = "D", desc = "Trash", fn = api.fs.trash, n = "api.fs.trash" },
  rename = { key = "r", desc = "Rename", fn = api.fs.rename, n = "api.fs.rename" },
  full_rename = { key = "<C-r>", desc = "Rename: Omit Filename", fn = api.fs.rename_sub, n = "api.fs.rename_sub" },
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

local function refactored(opts)
  -- mapping actions
  if opts.view and opts.view.mappings and opts.view.mappings.list then
    for _, m in pairs(opts.view.mappings.list) do
      if m.action == "toggle_ignored" then
        m.action = "toggle_git_ignored"
      end
    end
  end

  -- 2022/06/20
  utils.move_missing_val(opts, "update_focused_file", "update_cwd", opts, "update_focused_file", "update_root", true)
  utils.move_missing_val(opts, "", "update_cwd", opts, "", "sync_root_with_cwd", true)

  -- 2022/11/07
  utils.move_missing_val(opts, "", "open_on_tab", opts, "tab.sync", "open", false)
  utils.move_missing_val(opts, "", "open_on_tab", opts, "tab.sync", "close", true)
  utils.move_missing_val(opts, "", "ignore_buf_on_tab_change", opts, "tab.sync", "ignore", true)

  -- 2022/11/22
  utils.move_missing_val(opts, "renderer", "root_folder_modifier", opts, "renderer", "root_folder_label", true)

  -- 2023/01/01
  utils.move_missing_val(opts, "update_focused_file", "debounce_delay", opts, "view", "debounce_delay", true)

  -- 2023/01/08
  utils.move_missing_val(opts, "trash", "require_confirm", opts, "ui.confirm", "trash", true)

  -- 2023/01/15
  if opts.view and opts.view.adaptive_size ~= nil then
    if opts.view.adaptive_size and type(opts.view.width) ~= "table" then
      local width = opts.view.width
      opts.view.width = {
        min = width,
      }
    end
    opts.view.adaptive_size = nil
  end
end

local function removed(opts)
  if opts.auto_close then
    notify.warn "auto close feature has been removed, see note in the README (tips & reminder section)"
    opts.auto_close = nil
  end

  if opts.focus_empty_on_setup then
    notify.warn "focus_empty_on_setup has been removed and will be replaced by a new startup configuration. Please remove this option. See https://bit.ly/3yJch2T"
    opts.focus_empty_on_setup = nil
  end

  if opts.create_in_closed_folder then
    notify.warn "create_in_closed_folder has been removed and is now the default behaviour. You may use api.fs.create to add a file under your desired node."
  end
  opts.create_in_closed_folder = nil
end

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
  local lua = [[
local api = require('nvim-tree.api')

local on_attach = function(bufnr)

  -- please insert mappings from :help nvim-tree-default-mappings]]

  -- explicit removals
  if #remove_keys > 0 then
    lua = lua .. "\n\n  -- remove_keys"
  end
  for _, key in ipairs(remove_keys) do
    lua = lua .. "\n" .. string.format([[  vim.keymap.set('n', '%s', '', { buffer = bufnr })]], key)
    lua = lua .. "\n" .. string.format([[  vim.keymap.del('n', '%s', { buffer = bufnr })]], key)
  end

  -- list
  if #list > 0 then
    lua = lua .. "\n\n  -- view.mappings.list"
  end
  for _, m in ipairs(list) do
    local keys = type(m.key) == "table" and m.key or { m.key }
    for _, k in ipairs(keys) do
      if LEGACY_MAPPINGS[m.action] then
        lua = lua
          .. "\n"
          .. string.format(
            [[ vim.keymap.set('%s', '%s', %s, { desc = '%s', buffer = bufnr, noremap = true, silent = true, nowait = true })]],
            m.mode or "n",
            k,
            LEGACY_MAPPINGS[m.action].n,
            LEGACY_MAPPINGS[m.action].desc
          )
      elseif type(m.action_cb) == "function" then
        lua = lua .. "\n" .. string.format([[ vim.keymap.set('%s', '%s', function()]], m.mode or "n", k)
        lua = lua .. "\n" .. string.format [[   local node = api.tree.get_node_under_cursor()]]
        lua = lua .. "\n" .. string.format [[   -- your code goes here]]
        lua = lua
          .. "\n"
          .. string.format(
            [[ end, { desc = '%s', buffer = bufnr, noremap = true, silent = true, nowait = true })]],
            m.action
          )
      end
    end
  end

  lua = lua .. "\nend"

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
  M.on_attach_lua = generate_on_attach_lua(list, remove_keys)
end

function M.generate_on_attach()
  if #M.on_attach_lua > 0 then
    local name = "/tmp/my_on_attach.lua"
    local file = io.open(name, "w")
    io.output(file)
    io.write(M.on_attach_lua)
    io.close(file)
    open_file.fn("edit", name)
  else
    notify.info "no custom mappings"
  end
end

function M.migrate_legacy_options(opts)
  -- silently move
  refactored(opts)

  -- warn and delete
  removed(opts)
end

return M
