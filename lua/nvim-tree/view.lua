local a = vim.api

local M = {}

function M.nvim_tree_callback(callback_name)
  return string.format(":lua require'nvim-tree'.on_keypress('%s')<CR>", callback_name)
end

M.View = {
  bufnr = nil,
  winnr = nil,
  width = 30,
  side = 'left',
  auto_resize = false,
  winopts = {
    relativenumber = false,
    number = false,
    list = false,
    winfixwidth = true,
    winfixheight = true,
    foldenable = false,
    spell = false,
    signcolumn = 'yes',
    foldmethod = 'manual',
    foldcolumn = '0',
    winhl = 'EndOfBuffer:NvimTreeEndOfBuffer,Normal:NvimTreeNormal,CursorLine:NvimTreeCursorLine,VertSplit:NvimTreeVertSplit,SignColumn:Normal'
  },
  bufopts = {
    swapfile = false,
    buftype = 'nofile';
    modifiable = false;
    filetype = 'NvimTree';
    bufhidden = 'hide';
  },
  bindings = {
    ["<CR>"]           = M.nvim_tree_callback("edit"),
    ["o"]              = M.nvim_tree_callback("edit"),
    ["<2-LeftMouse>"]  = M.nvim_tree_callback("edit"),
    ["<2-RightMouse>"] = M.nvim_tree_callback("cd"),
    ["<C-]>"]          = M.nvim_tree_callback("cd"),
    ["<C-v>"]          = M.nvim_tree_callback("vsplit"),
    ["<C-x>"]          = M.nvim_tree_callback("split"),
    ["<C-t>"]          = M.nvim_tree_callback("tabnew"),
    ["<"]              = M.nvim_tree_callback("prev_sibling"),
    [">"]              = M.nvim_tree_callback("next_sibling"),
    ["P"]              = M.nvim_tree_callback("parent_node"),
    ["<BS>"]           = M.nvim_tree_callback("close_node"),
    ["<S-CR>"]         = M.nvim_tree_callback("close_node"),
    ["<Tab>"]          = M.nvim_tree_callback("preview"),
    ["K"]              = M.nvim_tree_callback("first_sibling"),
    ["J"]              = M.nvim_tree_callback("last_sibling"),
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
  }
}

-- set user options and create tree buffer (should never be wiped)
function M.setup()
  M.View.auto_resize = vim.g.nvim_tree_auto_resize or M.View.auto_resize
  M.View.side = vim.g.nvim_tree_side or M.View.side
  M.View.width = vim.g.nvim_tree_width or M.View.width

  M.View.bufnr = a.nvim_create_buf(false, false)
  for k, v in pairs(M.View.bufopts) do
    a.nvim_buf_set_option(M.View.bufnr, k, v)
  end
  a.nvim_buf_set_name(M.View.bufnr, 'NvimTree')

  if not vim.g.nvim_tree_disable_keybindings then
    M.View.bindings = vim.tbl_extend(
      'force',
      M.View.bindings,
      vim.g.nvim_tree_bindings or {}
    )
    for key, cb in pairs(M.View.bindings) do
      a.nvim_buf_set_keymap(M.View.bufnr, 'n', key, cb, { noremap = true, silent = true })
    end
  end
end

function M.win_open()
  return M.View.winnr ~= nil and a.nvim_win_is_valid(M.View.winnr)
end

function M.set_cursor(opts)
  if M.win_open() then
    a.nvim_win_set_cursor(M.View.winnr, opts)
  end
end

function M.focus(winnr, open_if_closed)
  local wnr = winnr or M.View.winnr

  if a.nvim_win_get_tabpage(wnr) ~= a.nvim_win_get_tabpage(0) then
    M.close()
    M.open()
    wnr = M.View.winnr
  elseif open_if_closed and not M.win_open() then
    M.open()
  end

  a.nvim_set_current_win(wnr)
end

function M.resize()
  if not M.View.auto_resize then
    return
  end

  a.nvim_win_set_width(M.View.winnr, M.View.width)
end

local move_tbl = {
  left = 'H',
  right = 'L',
  bottom = 'J',
  top = 'K',
}

function M.open()
  a.nvim_command("vnew")
  local move_to = move_tbl[M.View.side]
  a.nvim_command("wincmd "..move_to)
  a.nvim_command("vertical resize "..M.View.width)
  M.View.winnr = a.nvim_get_current_win()
  for k, v in pairs(M.View.winopts) do
    a.nvim_win_set_option(M.View.winnr, k, v)
  end

  vim.cmd("buffer "..M.View.bufnr)
  vim.cmd ":wincmd ="
end

function M.close()
  if not M.win_open() then return end
  if #a.nvim_list_wins() == 1 then
    return vim.cmd ':q!'
  end
  a.nvim_win_hide(M.View.winnr)
end

return M
