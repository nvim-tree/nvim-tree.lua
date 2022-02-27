local M = {}

local out_config = {
  "nvim_tree_disable_netrw",
  "nvim_tree_hijack_netrw",
  "nvim_tree_auto_open",
  "nvim_tree_auto_close",
  "nvim_tree_tab_open",
  "nvim_tree_update_cwd",
  "nvim_tree_hijack_cursor",
  "nvim_tree_system_open_command",
  "nvim_tree_system_open_command_args",
  "nvim_tree_follow",
  "nvim_tree_follow_update_path",
  "nvim_tree_lsp_diagnostics",
  "nvim_tree_auto_resize",
  "nvim_tree_bindings",
  "nvim_tree_disable_keybindings",
  "nvim_tree_disable_default_keybindings",
  "nvim_tree_hide_dotfiles",
  "nvim_tree_ignore",
  "nvim_tree_gitignore",
  "nvim_tree_disable_window_picker",
  "nvim_tree_window_picker_chars",
  "nvim_tree_window_picker_exclude",
}

local function migrate(o, d)
  if not o.view then
    o.view = {}
  end

  if vim.g.nvim_tree_disable_netrw and o.disable_netrw == d.disable_netrw then
    o.disable_netrw = vim.g.nvim_tree_disable_netrw ~= 0
  end
  if vim.g.nvim_tree_hijack_netrw and o.hijack_netrw == d.hijack_netrw then
    o.hijack_netrw = vim.g.nvim_tree_hijack_netrw ~= 0
  end

  if vim.g.nvim_tree_auto_open and o.open_on_setup == d.open_on_setup then
    o.open_on_setup = vim.g.nvim_tree_auto_open ~= 0
  end
  if vim.g.nvim_tree_auto_close and o.auto_close == d.auto_close then
    o.auto_close = vim.g.nvim_tree_auto_close ~= 0
  end

  if vim.g.nvim_tree_tab_open and o.open_on_tab == d.open_on_tab then
    o.open_on_tab = vim.g.nvim_tree_tab_open ~= 0
  end

  if vim.g.nvim_tree_update_cwd and o.update_cwd == d.update_cwd then
    o.update_cwd = vim.g.nvim_tree_update_cwd ~= 0
  end

  if vim.g.nvim_tree_hijack_cursor and o.hijack_cursor == d.hijack_cursor then
    o.hijack_cursor = vim.g.nvim_tree_hijack_cursor ~= 0
  end

  if vim.g.nvim_tree_system_open_command and not o.system_open.cmd then
    o.system_open.cmd = vim.g.nvim_tree_system_open_command
  end
  if vim.g.nvim_tree_system_open_command_args and #o.system_open.args == 0 then
    o.system_open.args = vim.g.nvim_tree_system_open_command_args
  end

  if vim.g.nvim_tree_follow and o.update_focused_file.enable == d.update_focused_file.enable then
    o.update_focused_file.enable = vim.g.nvim_tree_follow ~= 0
  end
  if vim.g.nvim_tree_follow_update_path and o.update_focused_file.update_cwd == d.update_focused_file.update_cwd then
    o.update_focused_file.update_cwd = vim.g.nvim_tree_follow_update_path ~= 0
  end

  if vim.g.nvim_tree_auto_resize and not o.view.auto_resize then
    o.view.auto_resize = vim.g.nvim_tree_auto_resize ~= 0
  end

  -- TODO
  -- nvim_tree_bindings
  -- nvim_tree_disable_keybindings
  -- nvim_tree_disable_default_keybindings
  -- if vim.g. and o. == d. then
  --   o. = vim.g. ~= 0
  -- end

  if vim.g.nvim_tree_hide_dotfiles and o.filters.dotfiles == d.filters.dotfiles then
    o.filters.dotfiles = vim.g.nvim_tree_hide_dotfiles ~= 0
  end

  if vim.g.nvim_tree_ignore and #o.filters.custom == 0 then
    o.filters.custom = vim.g.nvim_tree_ignore
  end
  if vim.g.nvim_tree_gitignore and o.git.ignore == d.git.ignore then
    o.git.ignore = vim.g.nvim_tree_gitignore ~= 0
  end

  if vim.g.nvim_tree_disable_window_picker and o.actions.open_file.window_picker.enable == d.actions.open_file.window_picker.enable then
    o.actions.open_file.window_picker.enable = vim.g.nvim_tree_disable_window_picker == 0
  end
  if vim.g.nvim_tree_window_picker_chars and not o.actions.open_file.window_picker.chars then
    o.actions.open_file.window_picker.chars = vim.g.nvim_tree_window_picker_chars
  end
  if vim.g.nvim_tree_window_picker_exclude and not o.actions.open_file.window_picker.exclude then
    o.actions.open_file.window_picker.exclude = vim.g.nvim_tree_window_picker_exclude
  end
end

function M.migrate_legacy_options(opts, default_opts)
  local x = vim.tbl_filter(function(v)
    return vim.fn.exists('g:'..v) ~= 0
  end, out_config)

  if #x > 0 then
    migrate(opts, default_opts)
    local msg = "Following options were moved to setup, see git.io/JPhyt: "
    require'nvim-tree.utils'.warn(msg..table.concat(x, ", "))
  end
end

return M

