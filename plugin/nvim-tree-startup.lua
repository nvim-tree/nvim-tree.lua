local is_initialized = false

if is_initialized then
  return
end
-- luacheck: ignore
is_initialized = true

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
  "nvim_tree_gitignore"
}

local x = vim.tbl_filter(function(v)
  return vim.fn.exists('g:'..v) ~= 0
end, out_config)

if #x > 0 then
  local msg = "following options are now set in the setup (:help nvim-tree.setup): "
  require'nvim-tree.utils'.echo_warning(msg..table.concat(x, " | "))
end
