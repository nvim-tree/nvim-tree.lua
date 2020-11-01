-- TODO: debug for lazy loading (seems like it doesn't work quite right with packer)
-- TODO: git
-- TODO: find file
-- TODO: symlink open ?
-- TODO: xdg open
-- TODO: refresh logic
-- TODO: watcher ?
-- TODO: multi explorer ? (would be hard to manage multiple cwds though)
local M = {}

M.config = {
  -- static
  width = 30,
  side = 'left',
  ignore = {'.git', 'node_modules'},
  show_ignored = false,
  show_indent_markers = false,
  hide_dotfiles = false,
  home_folder_modifier = "~",

  -- dynamics
  close_on_open_file = false,
  open_on_setup = false, --> will open when opening nvim as a pager (should not happen)

  -- autocmds
  close_when_last_window = false,
  set_cursor_on_bufenter = false, -- TODO
  keep_open_on_tabenter = false,
  resize_replace_on_bufenter = false,

  -- formatting / git / icons
  git = { -- TODO
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
    default = true,
  },

  -- actions
  keybindings = {
    ["<CR>"]  = ":lua require'nvim-tree'.open_file()<CR>",
    ["o"]     = ":lua require'nvim-tree'.open_file()<CR>",
    ["<C-v>"] = ":lua require'nvim-tree'.open_file('vsplit')<CR>",
    ["<C-x>"] = ":lua require'nvim-tree'.open_file('split')<CR>",
    ["<C-t>"] = ":lua require'nvim-tree'.open_file('tab')<CR>",
    ["<Tab>"] = ":lua require'nvim-tree'.open_file('preview')<CR>",
    ["<C-]>"] = ":lua require'nvim-tree'.change_cwd()<CR>",
    ["a"]     = ":lua require'nvim-tree'.create_file()<CR>", -- TODO
    ["d"]     = ":lua require'nvim-tree'.delete_file()<CR>", -- TODO
    ["r"]     = ":lua require'nvim-tree'.rename_file()<CR>", -- TODO
    ["x"]     = ":lua require'nvim-tree'.cut_file()<CR>", -- TODO
    ["c"]     = ":lua require'nvim-tree'.copy_file()<CR>", -- TODO
    ["p"]     = ":lua require'nvim-tree'.paste_file()<CR>", -- TODO
    ["[c"]    = ":lua require'nvim-tree'.go_to_prev('git')<CR>", -- TODO
    ["]c"]    = ":lua require'nvim-tree'.go_to_next('git')<CR>", -- TODO
  }
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("keep", opts or {}, M.config)

  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  require'nvim-tree.colors'.configure(M.config)
  require'nvim-tree.buffers.tree'.configure(M.config)
  require'nvim-tree.explorer'.configure(M.config)
  require'nvim-tree.format'.configure(M.config)
  require'nvim-tree.git'.configure(M.config)

  -- vim.cmd "au BufWritePost * lua require'nvim-tree'.refresh()"
  -- nope, maybe with watcher ?
  -- basically the watcher should, every updatetime ms, run a check function to see if a folder was modifier
  -- or the root was altered (ctime atime stuff)
  -- reload the appropriate nodes, and redraw the tree

  -- au BufEnter * lua require'tree'.buf_enter() -- this is the follow stuff
  -- au User FugitiveChanged lua require'tree'.refresh() -- this should be implemented with watcher
  --
  vim.cmd "command! NvimTreeOpen lua require'nvim-tree'.open()"
  vim.cmd "command! NvimTreeClose lua require'nvim-tree'.close()"
  vim.cmd "command! NvimTreeToggle lua require'nvim-tree'.toggle()"
  vim.cmd "command! NvimTreeRefresh lua require'nvim-tree'.refresh()"
  vim.cmd "command! NvimTreeClipboard lua require'nvim-tree'.print_clipboard()"
  vim.cmd "command! NvimTreeFindFile lua require'nvim-tree'.find_file(true)"
  vim.cmd "au! Colorscheme * lua require'nvim-tree.colors'.configure()"

  if M.config.keep_open_on_tabenter then
    vim.cmd "au TabEnter * lua require'nvim-tree'.redraw()"
  end

  if M.config.resize_replace_on_bufenter then
    vim.cmd "au BufEnter * lua require'nvim-tree.buffers.tree'.resize(true)"
  end

  if M.config.open_on_setup then
    vim.defer_fn(function()
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname == "" then bufname = "." end
      if bufname and vim.fn.isdirectory(bufname) == 0 then return end

      require'nvim-tree'.open(bufname)
    end, 1)
  end
end

return M
