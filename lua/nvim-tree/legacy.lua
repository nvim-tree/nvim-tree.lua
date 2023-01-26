local api = require "nvim-tree.api"
local utils = require "nvim-tree.utils"
local notify = require "nvim-tree.notify"
local open_file = require "nvim-tree.actions.node.open-file"
local keymap = require "nvim-tree.keymap"

local M = {
  on_attach_lua = "",
}

-- TODO complete list from DEFAULT_MAPPINGS from actions/init.lua
local LEGACY_MAPPINGS = {
  close_node = {
    key = "<BS>",
    fn = api.node.navigate.parent_close,
    t = "api.node.navigate.parent_close",
  },
}

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

local function generate_on_attach_lua(list, remove_keys, remove_defaults)
  local lua = [[
local api = require('nvim-tree.api')

local on_attach = function(bufnr)]]

  -- TODO generate from LEGACY_MAPPINGS; text table from default_on_attach is not worth the effort

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
        lua = lua .. "\n" .. string.format([[ vim.keymap.set('%s', '%s', %s, { desc = '%s', buffer = bufnr, noremap = true, silent = true, nowait = true })]], m.mode or "n", k, LEGACY_MAPPINGS[m.action].t, m.action)
      elseif type(m.action_cb) == "function" then
        lua = lua .. "\n" .. string.format([[ vim.keymap.set('%s', '%s', function()]], m.mode or "n", k)
        lua = lua .. "\n" .. string.format([[   local node = api.tree.get_node_under_cursor()]])
        lua = lua .. "\n" .. string.format([[   -- your code goes here]])
        lua = lua .. "\n" .. string.format([[ end, { desc = '%s', buffer = bufnr, noremap = true, silent = true, nowait = true })]], m.action)
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
  M.on_attach_lua = generate_on_attach_lua(list, remove_keys, remove_defaults)
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
