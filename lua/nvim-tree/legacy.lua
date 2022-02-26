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

local function migrate_window_picker(opts)
  if vim.g.nvim_tree_disable_window_picker then
    if opts.actions.open_file.window_picker.enable then
      opts.actions.open_file.window_picker.enable = vim.g.nvim_tree_disable_window_picker ~= 1
    end
  end

  if vim.g.nvim_tree_window_picker_chars then
    if opts.actions.open_file.window_picker.chars == nil then
      opts.actions.open_file.window_picker.chars = vim.g.nvim_tree_window_picker_chars
    end
  end

  if vim.g.nvim_tree_window_picker_exclude then
    if opts.actions.open_file.window_picker.exclude == nil then
      opts.actions.open_file.window_picker.exclude = vim.g.nvim_tree_window_picker_exclude
    end
  end
end

function M.migrate_legacy_options(opts)
  local x = vim.tbl_filter(function(v)
    return vim.fn.exists('g:'..v) ~= 0
  end, out_config)

  if #x > 0 then
    for _, opt in ipairs(x) do
      if opt == 'nvim_tree_disable_window_picker' or opt == 'nvim_tree_window_picker_chars' or opt == 'nvim_tree_window_picker_exclude' then
        migrate_window_picker(opts)
      end
    end

    local msg = "Following options were moved to setup, see git.io/JPhyt: "
    require'nvim-tree.utils'.warn(msg..table.concat(x, ", "))
  end
end

return M

