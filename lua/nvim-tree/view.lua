local a = vim.api

local M = {}

function M.nvim_tree_callback(callback_name)
  return string.format(":lua require'nvim-tree'.on_keypress('%s')<CR>", callback_name)
end

M.View = {
  bufnr = nil,
  tabpages = {},
  width = 30,
  side = 'left',
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
    winhl = table.concat({
      'EndOfBuffer:NvimTreeEndOfBuffer',
      'Normal:NvimTreeNormal',
      'CursorLine:NvimTreeCursorLine',
      'VertSplit:NvimTreeVertSplit',
      'SignColumn:NvimTreeNormal',
      'StatusLine:NvimTreeStatusLine',
      'StatusLineNC:NvimTreeStatuslineNC'
    }, ',')
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
    ["y"]              = M.nvim_tree_callback("copy_name"),
    ["Y"]              = M.nvim_tree_callback("copy_path"),
    ["gy"]             = M.nvim_tree_callback("copy_absolute_path"),
    ["[c"]             = M.nvim_tree_callback("prev_git_item"),
    ["]c"]             = M.nvim_tree_callback("next_git_item"),
    ["-"]              = M.nvim_tree_callback("dir_up"),
    ["q"]              = M.nvim_tree_callback("close"),
  }
}

---Find a rogue NvimTree buffer that might have been spawned by i.e. a session.
---@return integer|nil
local function find_rogue_buffer()
  for _, v in ipairs(a.nvim_list_bufs()) do
    if vim.fn.bufname(v) == "NvimTree" then
      return v
    end
  end
  return nil
end

---Check if the tree buffer is valid and loaded.
---@return boolean
local function is_buf_valid()
  return a.nvim_buf_is_valid(M.View.bufnr) and a.nvim_buf_is_loaded(M.View.bufnr)
end

---Find pre-existing NvimTree buffer, delete its windows then wipe it.
---@private
function M._wipe_rogue_buffer()
  local bn = find_rogue_buffer()
  if bn then
    local win_ids = vim.fn.win_findbuf(bn)
    for _, id in ipairs(win_ids) do
      if vim.fn.win_gettype(id) ~= "autocmd" then
        a.nvim_win_close(id, true)
      end
    end

    a.nvim_buf_set_name(bn, "")
    vim.schedule(function ()
      pcall(a.nvim_buf_delete, bn, {})
    end)
  end
end

-- set user options and create tree buffer (should never be wiped)
function M.setup()
  M.View.side = vim.g.nvim_tree_side or M.View.side
  M.View.width = vim.g.nvim_tree_width or M.View.width

  M.View.bufnr = a.nvim_create_buf(false, false)

  if not pcall(a.nvim_buf_set_name, M.View.bufnr, 'NvimTree') then
    M._wipe_rogue_buffer()
    a.nvim_buf_set_name(M.View.bufnr, 'NvimTree')
  end

  for k, v in pairs(M.View.bufopts) do
    vim.bo[M.View.bufnr][k] = v
  end

  if vim.g.nvim_tree_disable_keybindings ~= 1 then
    M.View.bindings = vim.tbl_extend(
      'force',
      M.View.bindings,
      vim.g.nvim_tree_bindings or {}
    )
    for key, cb in pairs(M.View.bindings) do
      a.nvim_buf_set_keymap(M.View.bufnr, 'n', key, cb, { noremap = true, silent = true, nowait = true })
    end
  end

  vim.cmd "au! BufWinEnter * lua require'nvim-tree.view'._prevent_buffer_override()"
end

local goto_tbl = {
  right = 'h',
  left = 'l',
  top = 'j',
  bottom = 'k',
}

function M._prevent_buffer_override()
  vim.schedule(function()
    local curwin = a.nvim_get_current_win()
    local curbuf = a.nvim_win_get_buf(curwin)
    if curwin ~= M.get_winnr() or curbuf == M.View.bufnr then return end

    vim.cmd("buffer "..M.View.bufnr)

    if #vim.api.nvim_list_wins() < 2 then
      vim.cmd("vsplit")
    else
      vim.cmd("wincmd "..goto_tbl[M.View.side])
    end
    vim.cmd("buffer "..curbuf)
  end)
end

function M.win_open(opts)
  if opts and opts.any_tabpage then
    for _, v in pairs(M.View.tabpages) do
      if  a.nvim_win_is_valid(v) then
        return true
      end
    end
    return false
  else
    return M.get_winnr() ~= nil and a.nvim_win_is_valid(M.get_winnr())
  end
end

function M.set_cursor(opts)
  if M.win_open() then
    pcall(a.nvim_win_set_cursor, M.get_winnr(), opts)
  end
end

function M.focus(winnr, open_if_closed)
  local wnr = winnr or M.get_winnr()

  if a.nvim_win_get_tabpage(wnr) ~= a.nvim_win_get_tabpage(0) then
    M.close()
    M.open()
    wnr = M.get_winnr()
  elseif open_if_closed and not M.win_open() then
    M.open()
  end

  a.nvim_set_current_win(wnr)
end

function M.resize()
  if not a.nvim_win_is_valid(M.get_winnr()) then
    return
  end

  a.nvim_win_set_width(M.get_winnr(), M.View.width)
end

local move_tbl = {
  left = 'H',
  right = 'L',
  bottom = 'J',
  top = 'K',
}

function M.open()
  if not is_buf_valid() then
    M.setup()
  end

  a.nvim_command("vsp")
  local move_to = move_tbl[M.View.side]
  a.nvim_command("wincmd "..move_to)
  a.nvim_command("vertical resize "..M.View.width)
  local winnr = a.nvim_get_current_win()
  M.View.tabpages[a.nvim_get_current_tabpage()] = winnr
  for k, v in pairs(M.View.winopts) do
    vim.wo[winnr][k] = v
  end

  vim.cmd("buffer "..M.View.bufnr)
  vim.cmd ":wincmd ="
end

function M.close()
  if not M.win_open() then return end
  if #a.nvim_list_wins() == 1 then
    local ans = vim.fn.input(
      '[NvimTree] this is the last open window, are you sure you want to quit nvim ? y/n: '
    )
    if ans == 'y' then
      vim.cmd "q!"
    end
    return
  end
  a.nvim_win_hide(M.get_winnr())
end

function M.get_winnr()
  return M.View.tabpages[a.nvim_get_current_tabpage()]
end

return M
