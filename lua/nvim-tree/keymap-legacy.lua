local api = require "nvim-tree.api"
local open_file = require "nvim-tree.actions.node.open-file"
local keymap = require "nvim-tree.keymap"
local notify = require "nvim-tree.notify"

local M = {
  -- only populated when legacy mappings active
  on_attach_lua = nil,

  -- API config.mappings.active .default
  legacy_default = {},
  legacy_active = {},

  -- used by generated on_attach
  on_attach = {
    list = {},
    unmapped_keys = {},
    remove_defaults = false,
  },
}

local BEGIN_ON_ATTACH = [[
--
-- This function has been generated from your
--   view.mappings.list
--   view.mappings.custom_only
--   remove_keymaps
--
-- You should add this function to your configuration and set on_attach = on_attach in the nvim-tree setup call.
--
-- Although care was taken to ensure correctness and completeness, your review is required.
--
-- Please check for the following issues in auto generated content:
--   "Mappings removed" is as you expect
--   "Mappings migrated" are correct
--
-- Please see https://github.com/nvim-tree/nvim-tree.lua/wiki/Migrating-To-on_attach for assistance in migrating.
--

local function on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end
]]

local END_ON_ATTACH = [[
end
]]

local REMOVAL_COMMENT_ON_ATTACH = [[


  -- Mappings removed via:
  --   remove_keymaps
  --   OR
  --   view.mappings.list..action = ""
  --
  -- The dummy set before del is done for safety, in case a default mapping does not exist.
  --
  -- You might tidy things by removing these along with their default mapping.
]]

local CUSTOM_COMMENT_ON_ATTACH = [[


  -- Mappings migrated from view.mappings.list
  --
  -- You will need to insert "your code goes here" for any mappings with a custom action_cb
]]

local NO_DEFAULTS_COMMENT_ON_ATTACH = [[


  -- Default mappings not inserted as:
  --  remove_keymaps = true
  --  OR
  --  view.mappings.custom_only = true
]]

local DEFAULT_ON_ATTACH = [[

  -- Default mappings. Feel free to modify or remove as you wish.
  --
  -- BEGIN_DEFAULT_ON_ATTACH
  vim.keymap.set('n', '<C-]>', api.tree.change_root_to_node,          opts('CD'))
  vim.keymap.set('n', '<C-e>', api.node.open.replace_tree_buffer,     opts('Open: In Place'))
  vim.keymap.set('n', '<C-k>', api.node.show_info_popup,              opts('Info'))
  vim.keymap.set('n', '<C-r>', api.fs.rename_sub,                     opts('Rename: Omit Filename'))
  vim.keymap.set('n', '<C-t>', api.node.open.tab,                     opts('Open: New Tab'))
  vim.keymap.set('n', '<C-v>', api.node.open.vertical,                opts('Open: Vertical Split'))
  vim.keymap.set('n', '<C-x>', api.node.open.horizontal,              opts('Open: Horizontal Split'))
  vim.keymap.set('n', '<BS>',  api.node.navigate.parent_close,        opts('Close Directory'))
  vim.keymap.set('n', '<CR>',  api.node.open.edit,                    opts('Open'))
  vim.keymap.set('n', '<Tab>', api.node.open.preview,                 opts('Open Preview'))
  vim.keymap.set('n', '>',     api.node.navigate.sibling.next,        opts('Next Sibling'))
  vim.keymap.set('n', '<',     api.node.navigate.sibling.prev,        opts('Previous Sibling'))
  vim.keymap.set('n', '.',     api.node.run.cmd,                      opts('Run Command'))
  vim.keymap.set('n', '-',     api.tree.change_root_to_parent,        opts('Up'))
  vim.keymap.set('n', 'a',     api.fs.create,                         opts('Create'))
  vim.keymap.set('n', 'bmv',   api.marks.bulk.move,                   opts('Move Bookmarked'))
  vim.keymap.set('n', 'B',     api.tree.toggle_no_buffer_filter,      opts('Toggle No Buffer'))
  vim.keymap.set('n', 'c',     api.fs.copy.node,                      opts('Copy'))
  vim.keymap.set('n', 'C',     api.tree.toggle_git_clean_filter,      opts('Toggle Git Clean'))
  vim.keymap.set('n', '[c',    api.node.navigate.git.prev,            opts('Prev Git'))
  vim.keymap.set('n', ']c',    api.node.navigate.git.next,            opts('Next Git'))
  vim.keymap.set('n', 'd',     api.fs.remove,                         opts('Delete'))
  vim.keymap.set('n', 'D',     api.fs.trash,                          opts('Trash'))
  vim.keymap.set('n', 'E',     api.tree.expand_all,                   opts('Expand All'))
  vim.keymap.set('n', 'e',     api.fs.rename_basename,                opts('Rename: Basename'))
  vim.keymap.set('n', ']e',    api.node.navigate.diagnostics.next,    opts('Next Diagnostic'))
  vim.keymap.set('n', '[e',    api.node.navigate.diagnostics.prev,    opts('Prev Diagnostic'))
  vim.keymap.set('n', 'F',     api.live_filter.clear,                 opts('Clean Filter'))
  vim.keymap.set('n', 'f',     api.live_filter.start,                 opts('Filter'))
  vim.keymap.set('n', 'g?',    api.tree.toggle_help,                  opts('Help'))
  vim.keymap.set('n', 'gy',    api.fs.copy.absolute_path,             opts('Copy Absolute Path'))
  vim.keymap.set('n', 'H',     api.tree.toggle_hidden_filter,         opts('Toggle Dotfiles'))
  vim.keymap.set('n', 'I',     api.tree.toggle_gitignore_filter,      opts('Toggle Git Ignore'))
  vim.keymap.set('n', 'J',     api.node.navigate.sibling.last,        opts('Last Sibling'))
  vim.keymap.set('n', 'K',     api.node.navigate.sibling.first,       opts('First Sibling'))
  vim.keymap.set('n', 'm',     api.marks.toggle,                      opts('Toggle Bookmark'))
  vim.keymap.set('n', 'o',     api.node.open.edit,                    opts('Open'))
  vim.keymap.set('n', 'O',     api.node.open.no_window_picker,        opts('Open: No Window Picker'))
  vim.keymap.set('n', 'p',     api.fs.paste,                          opts('Paste'))
  vim.keymap.set('n', 'P',     api.node.navigate.parent,              opts('Parent Directory'))
  vim.keymap.set('n', 'q',     api.tree.close,                        opts('Close'))
  vim.keymap.set('n', 'r',     api.fs.rename,                         opts('Rename'))
  vim.keymap.set('n', 'R',     api.tree.reload,                       opts('Refresh'))
  vim.keymap.set('n', 's',     api.node.run.system,                   opts('Run System'))
  vim.keymap.set('n', 'S',     api.tree.search_node,                  opts('Search'))
  vim.keymap.set('n', 'U',     api.tree.toggle_custom_filter,         opts('Toggle Hidden'))
  vim.keymap.set('n', 'W',     api.tree.collapse_all,                 opts('Collapse'))
  vim.keymap.set('n', 'x',     api.fs.cut,                            opts('Cut'))
  vim.keymap.set('n', 'y',     api.fs.copy.filename,                  opts('Copy Name'))
  vim.keymap.set('n', 'Y',     api.fs.copy.relative_path,             opts('Copy Relative Path'))
  vim.keymap.set('n', '<2-LeftMouse>',  api.node.open.edit,           opts('Open'))
  vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts('CD'))
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

local function all_mapped_keys(list)
  local mapped_keys = {}
  for _, map in pairs(list) do
    if map.action ~= "" then
      local keys = type(map.key) == "table" and map.key or { map.key }
      for _, key in ipairs(keys) do
        table.insert(mapped_keys, key)
      end
    end
  end
  return mapped_keys
end

local function all_unmapped_keys(list, remove_keys)
  local unmapped_keys = vim.deepcopy(remove_keys)
  for _, map in pairs(list) do
    if map.action == "" then
      local keys = type(map.key) == "table" and map.key or { map.key }
      for _, key in ipairs(keys) do
        table.insert(unmapped_keys, key)
      end
    end
  end
  return unmapped_keys
end

local function generate_on_attach_function(list, unmapped_keys, remove_defaults)
  M.on_attach.list = vim.deepcopy(list)
  M.on_attach.unmapped_keys = vim.deepcopy(unmapped_keys)
  M.on_attach.remove_defaults = remove_defaults

  return function(bufnr)
    -- apply defaults first
    if not M.on_attach.remove_defaults then
      keymap.default_on_attach(bufnr)
    end

    -- explicit removals
    for _, key in ipairs(M.on_attach.unmapped_keys) do
      vim.keymap.set("n", key, "", { buffer = bufnr })
      vim.keymap.del("n", key, { buffer = bufnr })
    end

    -- mappings
    for _, m in ipairs(M.on_attach.list) do
      local keys = type(m.key) == "table" and m.key or { m.key }
      for _, k in ipairs(keys) do
        local legacy_mapping = LEGACY_MAPPINGS[m.action] or LEGACY_MAPPINGS[m.cb]
        if legacy_mapping then
          -- straight action or cb, which generated an action string at setup time
          vim.keymap.set(
            m.mode or "n",
            k,
            legacy_mapping.fn,
            { desc = m.cb or m.action, buffer = bufnr, noremap = true, silent = true, nowait = true }
          )
        elseif type(m.action_cb) == "function" then
          -- action_cb
          vim.keymap.set(m.mode or "n", k, function()
            m.action_cb(api.tree.get_node_under_cursor())
          end, {
            desc = m.action or "no description",
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
          })
        end
      end
    end
  end
end

local function generate_on_attach_lua(list, unmapped_keys, remove_defaults)
  local lua = BEGIN_ON_ATTACH

  if remove_defaults then
    -- no defaults
    lua = lua .. NO_DEFAULTS_COMMENT_ON_ATTACH
  else
    -- defaults with explicit removals
    lua = lua .. "\n" .. DEFAULT_ON_ATTACH
    if #unmapped_keys > 0 then
      lua = lua .. REMOVAL_COMMENT_ON_ATTACH
    end
    for _, key in ipairs(unmapped_keys) do
      lua = lua .. string.format([[  vim.keymap.set('n', '%s', '', { buffer = bufnr })]], key) .. "\n"
      lua = lua .. string.format([[  vim.keymap.del('n', '%s', { buffer = bufnr })]], key) .. "\n"
    end
  end

  -- list
  if #list > 0 then
    lua = lua .. CUSTOM_COMMENT_ON_ATTACH
  end
  for _, m in ipairs(list) do
    local keys = type(m.key) == "table" and m.key or { m.key }
    for _, k in ipairs(keys) do
      local legacy_mapping = LEGACY_MAPPINGS[m.action] or LEGACY_MAPPINGS[m.cb]
      if legacy_mapping then
        lua = lua
          .. string.format(
            [[  vim.keymap.set('%s', '%s', %s, opts('%s'))]],
            m.mode or "n",
            k,
            legacy_mapping.n,
            legacy_mapping.desc
          )
          .. "\n"
      elseif type(m.action_cb) == "function" then
        lua = lua .. string.format([[  vim.keymap.set('%s', '%s', function()]], m.mode or "n", k) .. "\n"
        lua = lua .. [[    local node = api.tree.get_node_under_cursor()]] .. "\n"
        lua = lua .. [[    -- your code goes here]] .. "\n"
        lua = lua .. string.format([[  end, opts('%s'))]], m.action or "no description") .. "\n\n"
      end
    end
  end

  return lua .. "\n" .. END_ON_ATTACH
end

local function generate_legacy_default_mappings()
  local mappings = {}

  for a, m in pairs(LEGACY_MAPPINGS) do
    table.insert(mappings, {
      action = a,
      desc = m.desc,
      key = m.key,
    })
  end

  return mappings
end

local function generate_legacy_active_mappings(list, defaults, unmapped_keys, mapped_keys, remove_defaults)
  local filtered_defaults

  if remove_defaults then
    --
    -- unmap all defaults
    --
    filtered_defaults = {}
  else
    --
    -- unmap defaults by removal and override
    --
    local to_unmap = vim.fn.extend(unmapped_keys, mapped_keys)
    filtered_defaults = vim.tbl_filter(function(m)
      if type(m.key) == "table" then
        m.key = vim.tbl_filter(function(k)
          return not vim.tbl_contains(to_unmap, k)
        end, m.key)
        return #m.key > 0
      else
        return not vim.tbl_contains(to_unmap, m.key)
      end
    end, vim.deepcopy(defaults))
  end

  --
  -- remove user action = ""
  --
  local user_map = vim.tbl_filter(function(map)
    return map.action ~= ""
  end, list)

  --
  -- merge
  --
  return vim.fn.extend(filtered_defaults, user_map)
end

function M.generate_legacy_on_attach(opts)
  M.on_attach_lua = nil

  if type(opts.on_attach) == "function" then
    return
  end

  local list = opts.view and opts.view.mappings and opts.view.mappings.list or {}
  local remove_keymaps = type(opts.remove_keymaps) == "table" and opts.remove_keymaps or {}
  local remove_defaults = opts.remove_keymaps == true
    or opts.view and opts.view.mappings and opts.view.mappings.custom_only

  -- do nothing unless the user has configured something
  if #list == 0 and #remove_keymaps == 0 and not remove_defaults then
    return
  end

  local mapped_keys = all_mapped_keys(list)
  local unmapped_keys = all_unmapped_keys(list, remove_keymaps)

  opts.on_attach = generate_on_attach_function(list, unmapped_keys, remove_defaults)
  M.on_attach_lua = generate_on_attach_lua(list, unmapped_keys, remove_defaults)

  M.legacy_default = generate_legacy_default_mappings()
  M.legacy_active = generate_legacy_active_mappings(list, M.legacy_default, unmapped_keys, mapped_keys, remove_defaults)
end

function M.cmd_generate_on_attach()
  if not M.on_attach_lua then
    notify.info "No view.mappings.list for on_attach generation."
    return
  end

  local name = "/tmp/my_on_attach.lua"
  local file = io.output(name)
  io.write(M.on_attach_lua)
  io.close(file)
  open_file.fn("edit", name)
end

function M.active_mappings_clone()
  return vim.deepcopy(M.legacy_active)
end

function M.default_mappings_clone()
  return vim.deepcopy(M.legacy_default)
end

return M
