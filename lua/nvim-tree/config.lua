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

local function get_lua_cb(cb_name)
  return string.format(":lua require'nvim-tree'.on_keypress('%s')<CR>", cb_name)
end

function M.get_bindings()
  local keybindings = vim.g.nvim_tree_bindings or {}
  return vim.tbl_extend('force', {
    ["<CR>"]           = get_lua_cb("edit"),
    ["o"]              = get_lua_cb("edit"),
    ["<2-LeftMouse>"]  = get_lua_cb("edit"),
    ["<2-RightMouse>"] = get_lua_cb("cd"),
    ["<C-]>"]          = get_lua_cb("cd"),
    ["<C-v>"]          = get_lua_cb("vsplit"),
    ["<C-x>"]          = get_lua_cb("split"),
    ["<C-t>"]          = get_lua_cb("tabnew"),
    ["<BS>"]           = get_lua_cb("close_node"),
    ["<S-CR>"]         = get_lua_cb("close_node"),
    ["<Tab>"]          = get_lua_cb("preview"),
    ["I"]              = get_lua_cb("toggle_ignored"),
    ["H"]              = get_lua_cb("toggle_dotfiles"),
    ["R"]              = get_lua_cb("refresh"),
    ["a"]              = get_lua_cb("create"),
    ["d"]              = get_lua_cb("remove"),
    ["r"]              = get_lua_cb("rename"),
    ["<C-r>"]          = get_lua_cb("full_rename"),
    ["x"]              = get_lua_cb("cut"),
    ["c"]              = get_lua_cb("copy"),
    ["p"]              = get_lua_cb("paste"),
    ["[c"]             = get_lua_cb("prev_git_item"),
    ["]c"]             = get_lua_cb("next_git_item"),
    ["-"]              = get_lua_cb("dir_up"),
    ["q"]              = get_lua_cb("close"),
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
