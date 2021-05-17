local M = {}

function M.get_icon_state()
  local show_icons = vim.g.nvim_tree_show_icons or { git = 1, folders = 1, files = 1 }
  local icons = {
    default = "",
    symlink = "",
    git_icons = {
      unstaged = "✗",
      staged = "✓",
      unmerged = "",
      renamed = "➜",
      untracked = "★",
      deleted = "",
      ignored = "◌"
    },
    folder_icons = {
      default = "",
      open = "",
      empty = "",
      empty_open = "",
      symlink = "",
      symlink_open = "",
    },
    lsp = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  }

  local user_icons = vim.g.nvim_tree_icons
  if user_icons then
    if user_icons.default then
      icons.default = user_icons.default
      icons.symlink = user_icons.default
    end
    if user_icons.symlink then
      icons.symlink = user_icons.symlink
    end
    for key, val in pairs(user_icons.git or {}) do
      if icons.git_icons[key] then
        icons.git_icons[key] = val
      end
    end
    for key, val in pairs(user_icons.folder or {}) do
      if icons.folder_icons[key] then
        icons.folder_icons[key] = val
      end
    end
    for key, val in pairs(user_icons.lsp or {}) do
      if icons.lsp[key] then
        icons.lsp[key] = val
      end
    end
  end

  return {
    show_file_icon = show_icons.files == 1 and vim.g.nvim_web_devicons == 1,
    show_folder_icon = show_icons.folders == 1,
    show_git_icon = show_icons.git == 1,
    icons = icons
  }
end

function M.nvim_tree_callback(callback_name)
  return string.format(":lua require'nvim-tree'.on_keypress('%s')<CR>", callback_name)
end

function M.window_options()
  local opts = {}
  if vim.g.nvim_tree_side == 'right' then
    opts.open_command = 'h'
    opts.preview_command = 'l'
    opts.split_command = 'aboveleft'
  else
    opts.open_command = 'l'
    opts.preview_command = 'h'
    opts.split_command = 'belowright'
  end

  return opts
end

return M
