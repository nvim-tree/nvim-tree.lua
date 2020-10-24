local M = {}

M.config = {
  width = 30,
  side = 'left',
  ignore = {'.git', 'node_modules'},
  show_ignored = false,
  update_cursor = false,
  auto_open = false,
  auto_close = false,
  close_on_open_file = false,
  show_indent_markers = false,
  hide_dotfiles = false,
  home_folder_modifier = "~",
  tab_open = false,
  keep_width = false,
  git = {
    show = {
      icons = true,
      highlight = true,
    },
    icons = {
      unstaged = "✗",
      staged = "✓",
      unmerged = "",
      renamed = "➜",
      untracked = "★",
      deleted = ""
    }
  },
  folders = {
    show = true,
    icons = {
      closed = "",
      opened = ""
    }
  },
  symlink_icon = "",
  web_devicons = {
    show = true,
    default = true, -- true || false || replacement str
  },
  keybindings = {
    ["<CR>"]  = ":lua require'nvim-tree'.open_file()<CR>",
    ["o"]     = ":lua require'nvim-tree'.open_file()<CR>",
    ["<C-v>"] = ":lua require'nvim-tree'.open_file('vsplit')<CR>",
    ["<C-x>"] = ":lua require'nvim-tree'.open_file('split')<CR>",
    ["<C-t>"] = ":lua require'nvim-tree'.open_file('tab')<CR>",
    ["<Tab>"] = ":lua require'nvim-tree'.open_file('preview')<CR>",
    ["<C-]>"] = ":lua require'nvim-tree'.change_cwd()<CR>",
    ["a"]     = ":lua require'nvim-tree'.create_file()<CR>",
    ["d"]     = ":lua require'nvim-tree'.delete_file()<CR>",
    ["r"]     = ":lua require'nvim-tree'.rename_file()<CR>",
    ["x"]     = ":lua require'nvim-tree'.cut_file()<CR>",
    ["c"]     = ":lua require'nvim-tree'.copy_file()<CR>",
    ["p"]     = ":lua require'nvim-tree'.paste_file()<CR>",
    ["[c"]    = ":lua require'nvim-tree'.go_to_prev('git')<CR>",
    ["]c"]    = ":lua require'nvim-tree'.go_to_next('git')<CR>",
  }
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("keep", opts or {}, M.config)

  require'nvim-tree.git'.configure(M.config)
  require'nvim-tree.colors'.configure(M.config)
  require'nvim-tree.buffers.tree'.configure(M.config)
  require'nvim-tree.explorer'.configure(M.config)

  if M.config.auto_open then
    require'nvim-tree'.open()
  end
end

return M
