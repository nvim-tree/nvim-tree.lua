local M = {}

M.config = {
  width = 30,
  side = 'left',
  ignore = {'.git', 'node_modules'},
  show_ignored = false, -- TODO
  update_cursor = false, -- TODO
  auto_open = false, -- CHECK
  auto_close = false, -- CHECK
  close_on_open_file = false,
  show_indent_markers = false,
  hide_dotfiles = false, -- CHECK
  home_folder_modifier = "~", -- CHECK
  tab_open = false, -- CHECK
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
  require'nvim-tree.format'.configure(M.config)

  if M.config.auto_open then
    require'nvim-tree'.open()
  end

  if M.config.tab_open then
    vim.cmd "au TabEnter * lua require'nvim-tree'.redraw()"
  end

  if M.config.keep_width then
    vim.cmd "au BufEnter * lua require'nvim-tree.buffers.tree'.resize(true)"
  end
end

return M
