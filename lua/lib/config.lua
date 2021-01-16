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
      deleted = ""
    },
    folder_icons = {
      default = "",
      open = "",
      symlink = "",
    }
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
  end

  return {
    show_file_icon = show_icons.files == 1 and vim.g.nvim_web_devicons == 1,
    show_folder_icon = show_icons.folders == 1,
    show_git_icon = show_icons.git == 1,
    icons = icons
  }
end

function M.get_bindings()
  local keybindings = vim.g.nvim_tree_bindings or {}
  return {
    edit            = keybindings.edit or {'<CR>', 'o'},
    edit_vsplit     = keybindings.edit_vsplit or '<C-v>',
    edit_split      = keybindings.edit_split or '<C-x>',
    edit_tab        = keybindings.edit_tab or '<C-t>',
    close_node      = keybindings.close_node or {'<S-CR>', '<BS>'},
    preview         = keybindings.preview or '<Tab>',
    toggle_ignored  = keybindings.toggle_ignored or 'I',
    toggle_dotfiles = keybindings.toggle_dotfiles or 'H',
    refresh         = keybindings.refresh or 'R',
    cd              = keybindings.cd or '<C-]>',
    create          = keybindings.create or 'a',
    remove          = keybindings.remove or 'd',
    rename          = keybindings.rename or 'r',
    cut             = keybindings.cut or 'x',
    copy            = keybindings.copy or 'c',
    paste           = keybindings.paste or 'p',
    prev_git_item   = keybindings.prev_git_item or '[c',
    next_git_item   = keybindings.next_git_item or ']c',
    dir_up          = keybindings.dir_up or '-',
    close           = keybindings.close or 'q',
  }
end

function M.window_options()
  local opts = {}
  opts.winhl = 'EndOfBuffer:NvimTreeEndOfBuffer,Normal:NvimTreeNormal,CursorLine:NvimTreeCursorLine,VertSplit:NvimTreeVertSplit'
  if vim.g.nvim_tree_side == 'right' then
    opts.side = 'L'
    opts.open_command = 'h'
    opts.preview_command = 'l'
    opts.split_command = 'nosplitright'
  else
    opts.side = 'H'
    opts.open_command = 'l'
    opts.preview_command = 'h'
    opts.split_command = 'splitright'
  end

  return opts
end

return M
