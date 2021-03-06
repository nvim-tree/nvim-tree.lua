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
      empty = "",
      empty_open = "",
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

function M.nvim_tree_callback(callback_name)
  return string.format(":lua require'nvim-tree'.on_keypress('%s')<CR>", callback_name)
end

function M.get_bindings()
  local keybindings = vim.g.nvim_tree_bindings or {}
  return vim.tbl_extend('force', {
    ["<CR>"]           = M.nvim_tree_callback("edit"),
    ["o"]              = M.nvim_tree_callback("edit"),
    ["<2-LeftMouse>"]  = M.nvim_tree_callback("edit"),
    ["<2-RightMouse>"] = M.nvim_tree_callback("cd"),
    ["<C-]>"]          = M.nvim_tree_callback("cd"),
    ["<C-v>"]          = M.nvim_tree_callback("vsplit"),
    ["<C-x>"]          = M.nvim_tree_callback("split"),
    ["<C-t>"]          = M.nvim_tree_callback("tabnew"),
    ["<BS>"]           = M.nvim_tree_callback("close_node"),
    ["<S-CR>"]         = M.nvim_tree_callback("close_node"),
    ["<Tab>"]          = M.nvim_tree_callback("preview"),
    ["I"]              = M.nvim_tree_callback("toggle_ignored"),
    ["H"]              = M.nvim_tree_callback("toggle_dotfiles"),
    ["R"]              = M.nvim_tree_callback("refresh"),
    ["a"]              = M.nvim_tree_callback("create"),
    ["d"]              = M.nvim_tree_callback("remove"),
    ["r"]              = M.nvim_tree_callback("rename"),
    ["<C-r>"]          = M.nvim_tree_callback("full_rename"),
    ["x"]              = M.nvim_tree_callback("cut"),
    ["c"]              = M.nvim_tree_callback("copy"),
    ["p"]              = M.nvim_tree_callback("paste"),
    ["[c"]             = M.nvim_tree_callback("prev_git_item"),
    ["]c"]             = M.nvim_tree_callback("next_git_item"),
    ["-"]              = M.nvim_tree_callback("dir_up"),
    ["q"]              = M.nvim_tree_callback("close"),
  }, keybindings)
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
