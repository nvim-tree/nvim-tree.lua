local utils = require "nvim-tree.utils"

local M = {}

-- TODO update bit.ly/3vIpEOJ when adding a migration

-- migrate the g: to o if the user has not specified that when calling setup
local g_migrations = {
  nvim_tree_disable_netrw = function(o)
    if o.disable_netrw == nil then
      o.disable_netrw = vim.g.nvim_tree_disable_netrw ~= 0
    end
  end,

  nvim_tree_hijack_netrw = function(o)
    if o.hijack_netrw == nil then
      o.hijack_netrw = vim.g.nvim_tree_hijack_netrw ~= 0
    end
  end,

  nvim_tree_auto_open = function(o)
    if o.open_on_setup == nil then
      o.open_on_setup = vim.g.nvim_tree_auto_open ~= 0
    end
  end,

  nvim_tree_tab_open = function(o)
    if o.open_on_tab == nil then
      o.open_on_tab = vim.g.nvim_tree_tab_open ~= 0
    end
  end,

  nvim_tree_update_cwd = function(o)
    if o.update_cwd == nil then
      o.update_cwd = vim.g.nvim_tree_update_cwd ~= 0
    end
  end,

  nvim_tree_hijack_cursor = function(o)
    if o.hijack_cursor == nil then
      o.hijack_cursor = vim.g.nvim_tree_hijack_cursor ~= 0
    end
  end,

  nvim_tree_system_open_command = function(o)
    utils.table_create_missing(o, "system_open")
    if o.system_open.cmd == nil then
      o.system_open.cmd = vim.g.nvim_tree_system_open_command
    end
  end,

  nvim_tree_system_open_command_args = function(o)
    utils.table_create_missing(o, "system_open")
    if o.system_open.args == nil then
      o.system_open.args = vim.g.nvim_tree_system_open_command_args
    end
  end,

  nvim_tree_follow = function(o)
    utils.table_create_missing(o, "update_focused_file")
    if o.update_focused_file.enable == nil then
      o.update_focused_file.enable = vim.g.nvim_tree_follow ~= 0
    end
  end,

  nvim_tree_follow_update_path = function(o)
    utils.table_create_missing(o, "update_focused_file")
    if o.update_focused_file.update_cwd == nil then
      o.update_focused_file.update_cwd = vim.g.nvim_tree_follow_update_path ~= 0
    end
  end,

  nvim_tree_lsp_diagnostics = function(o)
    utils.table_create_missing(o, "diagnostics")
    if o.diagnostics.enable == nil then
      o.diagnostics.enable = vim.g.nvim_tree_lsp_diagnostics ~= 0
      if o.diagnostics.show_on_dirs == nil then
        o.diagnostics.show_on_dirs = vim.g.nvim_tree_lsp_diagnostics ~= 0
      end
    end
  end,

  nvim_tree_auto_resize = function(o)
    utils.table_create_missing(o, "actions.open_file")
    if o.actions.open_file.resize_window == nil then
      o.actions.open_file.resize_window = vim.g.nvim_tree_auto_resize ~= 0
    end
  end,

  nvim_tree_bindings = function(o)
    utils.table_create_missing(o, "view.mappings")
    if o.view.mappings.list == nil then
      o.view.mappings.list = vim.g.nvim_tree_bindings
    end
  end,

  nvim_tree_disable_keybindings = function(o)
    utils.table_create_missing(o, "view.mappings")
    if o.view.mappings.custom_only == nil then
      if vim.g.nvim_tree_disable_keybindings ~= 0 then
        o.view.mappings.custom_only = true
        -- specify one mapping so that defaults do not apply
        o.view.mappings.list = {
          { key = "g?", action = "" },
        }
      end
    end
  end,

  nvim_tree_disable_default_keybindings = function(o)
    utils.table_create_missing(o, "view.mappings")
    if o.view.mappings.custom_only == nil then
      o.view.mappings.custom_only = vim.g.nvim_tree_disable_default_keybindings ~= 0
    end
  end,

  nvim_tree_hide_dotfiles = function(o)
    utils.table_create_missing(o, "filters")
    if o.filters.dotfiles == nil then
      o.filters.dotfiles = vim.g.nvim_tree_hide_dotfiles ~= 0
    end
  end,

  nvim_tree_ignore = function(o)
    utils.table_create_missing(o, "filters")
    if o.filters.custom == nil then
      o.filters.custom = vim.g.nvim_tree_ignore
    end
  end,

  nvim_tree_gitignore = function(o)
    utils.table_create_missing(o, "git")
    if o.git.ignore == nil then
      o.git.ignore = vim.g.nvim_tree_gitignore ~= 0
    end
  end,

  nvim_tree_disable_window_picker = function(o)
    utils.table_create_missing(o, "actions.open_file.window_picker")
    if o.actions.open_file.window_picker.enable == nil then
      o.actions.open_file.window_picker.enable = vim.g.nvim_tree_disable_window_picker == 0
    end
  end,

  nvim_tree_window_picker_chars = function(o)
    utils.table_create_missing(o, "actions.open_file.window_picker")
    if o.actions.open_file.window_picker.chars == nil then
      o.actions.open_file.window_picker.chars = vim.g.nvim_tree_window_picker_chars
    end
  end,

  nvim_tree_window_picker_exclude = function(o)
    utils.table_create_missing(o, "actions.open_file.window_picker")
    if o.actions.open_file.window_picker.exclude == nil then
      o.actions.open_file.window_picker.exclude = vim.g.nvim_tree_window_picker_exclude
    end
  end,

  nvim_tree_quit_on_open = function(o)
    utils.table_create_missing(o, "actions.open_file")
    if o.actions.open_file.quit_on_open == nil then
      o.actions.open_file.quit_on_open = vim.g.nvim_tree_quit_on_open == 1
    end
  end,

  nvim_tree_change_dir_global = function(o)
    utils.table_create_missing(o, "actions.change_dir")
    if o.actions.change_dir.global == nil then
      o.actions.change_dir.global = vim.g.nvim_tree_change_dir_global == 1
    end
  end,

  nvim_tree_indent_markers = function(o)
    utils.table_create_missing(o, "renderer.indent_markers")
    if o.renderer.indent_markers.enable == nil then
      o.renderer.indent_markers.enable = vim.g.nvim_tree_indent_markers == 1
    end
  end,

  nvim_tree_add_trailing = function(o)
    utils.table_create_missing(o, "renderer")
    if o.renderer.add_trailing == nil then
      o.renderer.add_trailing = vim.g.nvim_tree_add_trailing == 1
    end
  end,

  nvim_tree_highlight_opened_files = function(o)
    utils.table_create_missing(o, "renderer")
    if o.renderer.highlight_opened_files == nil then
      if vim.g.nvim_tree_highlight_opened_files == 1 then
        o.renderer.highlight_opened_files = "icon"
      elseif vim.g.nvim_tree_highlight_opened_files == 2 then
        o.renderer.highlight_opened_files = "name"
      elseif vim.g.nvim_tree_highlight_opened_files == 3 then
        o.renderer.highlight_opened_files = "all"
      end
    end
  end,

  nvim_tree_root_folder_modifier = function(o)
    utils.table_create_missing(o, "renderer")
    if o.renderer.root_folder_modifier == nil then
      o.renderer.root_folder_modifier = vim.g.nvim_tree_root_folder_modifier
    end
  end,

  nvim_tree_special_files = function(o)
    utils.table_create_missing(o, "renderer")
    if o.renderer.special_files == nil and type(vim.g.nvim_tree_special_files) == "table" then
      o.renderer.special_files = {}
      for k, v in pairs(vim.g.nvim_tree_special_files) do
        if v ~= 0 then
          table.insert(o.renderer.special_files, k)
        end
      end
    end
  end,

  nvim_tree_icon_padding = function(o)
    utils.table_create_missing(o, "renderer.icons")
    if o.renderer.icons.padding == nil then
      o.renderer.icons.padding = vim.g.nvim_tree_icon_padding
    end
  end,

  nvim_tree_symlink_arrow = function(o)
    utils.table_create_missing(o, "renderer.icons")
    if o.renderer.icons.symlink_arrow == nil then
      o.renderer.icons.symlink_arrow = vim.g.nvim_tree_symlink_arrow
    end
  end,

  nvim_tree_show_icons = function(o)
    utils.table_create_missing(o, "renderer.icons")
    if o.renderer.icons.show == nil and type(vim.g.nvim_tree_show_icons) == "table" then
      o.renderer.icons.show = {}
      o.renderer.icons.show.file = vim.g.nvim_tree_show_icons.files == 1
      o.renderer.icons.show.folder = vim.g.nvim_tree_show_icons.folders == 1
      o.renderer.icons.show.folder_arrow = vim.g.nvim_tree_show_icons.folder_arrows == 1
      o.renderer.icons.show.git = vim.g.nvim_tree_show_icons.git == 1
    end
  end,

  nvim_tree_icons = function(o)
    utils.table_create_missing(o, "renderer.icons")
    if o.renderer.icons.glyphs == nil and type(vim.g.nvim_tree_icons) == "table" then
      o.renderer.icons.glyphs = vim.g.nvim_tree_icons
    end
  end,

  nvim_tree_git_hl = function(o)
    utils.table_create_missing(o, "renderer")
    if o.renderer.highlight_git == nil then
      o.renderer.highlight_git = vim.g.nvim_tree_git_hl == 1
    end
  end,

  nvim_tree_group_empty = function(o)
    utils.table_create_missing(o, "renderer")
    if o.renderer.group_empty == nil then
      o.renderer.group_empty = vim.g.nvim_tree_group_empty == 1
    end
  end,

  nvim_tree_respect_buf_cwd = function(o)
    if o.respect_buf_cwd == nil then
      o.respect_buf_cwd = vim.g.nvim_tree_respect_buf_cwd == 1
    end
  end,

  nvim_tree_create_in_closed_folder = function(o)
    if o.create_in_closed_folder == nil then
      o.create_in_closed_folder = vim.g.nvim_tree_create_in_closed_folder == 1
    end
  end,
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
  utils.move_missing_val(opts, "update_focused_file", "update_cwd", opts, "update_focused_file", "update_root")
  utils.move_missing_val(opts, "", "update_cwd", opts, "", "sync_root_with_cwd")
end

local function removed(opts)
  if opts.auto_close then
    utils.notify.warn "auto close feature has been removed, see note in the README (tips & reminder section)"
    opts.auto_close = nil
  end

  if opts.focus_empty_on_setup then
    utils.notify.warn "focus_empty_on_setup has been removed and will be replaced by a new startup configuration. Please remove this option. See https://bit.ly/3yJch2T"
  end
  opts.focus_empty_on_setup = nil
end

function M.migrate_legacy_options(opts)
  -- g: options
  local msg
  for g, m in pairs(g_migrations) do
    if vim.fn.exists("g:" .. g) ~= 0 then
      m(opts)
      msg = (msg and msg .. ", " or "Following options were moved to setup, see bit.ly/3vIpEOJ: ") .. g
    end
  end
  if msg then
    utils.notify.warn(msg)
  end

  -- silently move
  refactored(opts)

  -- warn and delete
  removed(opts)
end

return M
