local a = vim.api

local M = {}

function M.nvim_tree_callback(callback_name)
  return string.format(":lua require'nvim-tree'.on_keypress('%s')<CR>", callback_name)
end

M.View = {
  bufnr = nil,
  tabpages = {},
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
    cursorcolumn = false,
    colorcolumn = '0',
    wrap = false,
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
    { name = 'swapfile', val = false },
    { name = 'buftype', val = 'nofile' },
    { name = 'modifiable', val = false },
    { name = 'filetype', val = 'NvimTree' },
    { name = 'bufhidden', val = 'hide' }
  },
  mappings = {
    { key = {"<CR>", "o", "<2-LeftMouse>"}, cb = M.nvim_tree_callback("edit") },
    { key = {"<2-RightMouse>", "<C-]>"},    cb = M.nvim_tree_callback("cd") },
    { key = "<C-v>",                        cb = M.nvim_tree_callback("vsplit") },
    { key = "<C-x>",                        cb = M.nvim_tree_callback("split") },
    { key = "<C-t>",                        cb = M.nvim_tree_callback("tabnew") },
    { key = "<",                            cb = M.nvim_tree_callback("prev_sibling") },
    { key = ">",                            cb = M.nvim_tree_callback("next_sibling") },
    { key = "P",                            cb = M.nvim_tree_callback("parent_node") },
    { key = "<BS>",                         cb = M.nvim_tree_callback("close_node") },
    { key = "<S-CR>",                       cb = M.nvim_tree_callback("close_node") },
    { key = "<Tab>",                        cb = M.nvim_tree_callback("preview") },
    { key = "K",                            cb = M.nvim_tree_callback("first_sibling") },
    { key = "J",                            cb = M.nvim_tree_callback("last_sibling") },
    { key = "I",                            cb = M.nvim_tree_callback("toggle_ignored") },
    { key = "H",                            cb = M.nvim_tree_callback("toggle_dotfiles") },
    { key = "R",                            cb = M.nvim_tree_callback("refresh") },
    { key = "a",                            cb = M.nvim_tree_callback("create") },
    { key = "d",                            cb = M.nvim_tree_callback("remove") },
    { key = "r",                            cb = M.nvim_tree_callback("rename") },
    { key = "<C-r>",                        cb = M.nvim_tree_callback("full_rename") },
    { key = "x",                            cb = M.nvim_tree_callback("cut") },
    { key = "c",                            cb = M.nvim_tree_callback("copy") },
    { key = "p",                            cb = M.nvim_tree_callback("paste") },
    { key = "y",                            cb = M.nvim_tree_callback("copy_name") },
    { key = "Y",                            cb = M.nvim_tree_callback("copy_path") },
    { key = "gy",                           cb = M.nvim_tree_callback("copy_absolute_path") },
    { key = "[c",                           cb = M.nvim_tree_callback("prev_git_item") },
    { key = "]c",                           cb = M.nvim_tree_callback("next_git_item") },
    { key = "-",                            cb = M.nvim_tree_callback("dir_up") },
    { key = "s",                            cb = M.nvim_tree_callback("system_open") },
    { key = "q",                            cb = M.nvim_tree_callback("close") },
    { key = "g?",                           cb = M.nvim_tree_callback("toggle_help") }
  }
}

local function wipe_rogue_buffer()
  for _, bn in ipairs(a.nvim_list_bufs()) do
    if vim.fn.bufname(bn) == "NvimTree" then
      return pcall(a.nvim_buf_delete, bn, { force = true })
    end
  end
end

local function create_buffer()
  wipe_rogue_buffer()
  M.View.bufnr = a.nvim_create_buf(false, false)
  a.nvim_buf_set_name(M.View.bufnr, 'NvimTree')

  for _, opt in ipairs(M.View.bufopts) do
    vim.bo[M.View.bufnr][opt.name] = opt.val
  end

  for _, b in pairs(M.View.mappings) do
    if type(b.key) == "table" then
      for _, key in pairs(b.key) do
        a.nvim_buf_set_keymap(M.View.bufnr, b.mode or 'n', key, b.cb, { noremap = true, silent = true, nowait = true })
      end
    else
      a.nvim_buf_set_keymap(M.View.bufnr, b.mode or 'n', b.key, b.cb, { noremap = true, silent = true, nowait = true })
    end
  end
end

local DEFAULT_CONFIG = {
  width = 30,
  side = 'left',
  auto_resize = false,
  mappings = {
    custom_only = false,
    list = {}
  }
}

function M.setup(opts)
  local options = vim.tbl_deep_extend('force', DEFAULT_CONFIG, opts)
  M.View.side = options.side
  M.View.width = options.width
  M.View.auto_resize = opts.auto_resize
  if options.mappings.custom_only then
    M.View.mappings = options.mappings.list
  else
    M.View.mappings = vim.fn.extend(M.View.mappings, options.mappings.list)
  end

  vim.cmd "augroup NvimTreeView"
  vim.cmd "au!"
  vim.cmd "au BufWinEnter,BufWinLeave * lua require'nvim-tree.view'._prevent_buffer_override()"
  vim.cmd "au BufEnter,BufNewFile * lua require'nvim-tree'.open_on_directory()"
  vim.cmd "augroup END"

  create_buffer()
end

local move_cmd = {
  right = 'h',
  left = 'l',
  top = 'j',
  bottom = 'k',
}

function M._prevent_buffer_override()
  vim.schedule(function()
    local curwin = a.nvim_get_current_win()
    local curbuf = a.nvim_win_get_buf(curwin)

    if curwin ~= M.get_winnr() or curbuf == M.View.bufnr then
      return
    end

    if a.nvim_buf_is_loaded(M.View.bufnr) and a.nvim_buf_is_valid(M.View.bufnr) then
      -- pcall necessary to avoid erroring with `mark not set` although no mark are set
      -- this avoid other issues
      pcall(vim.api.nvim_win_set_buf, M.get_winnr(), M.View.bufnr)
    end

    local bufname = a.nvim_buf_get_name(curbuf)
    local isdir = vim.fn.isdirectory(bufname) == 1
    if isdir or not bufname or bufname == "" then
      return
    end

    if #vim.api.nvim_list_wins() < 2 then
      vim.cmd("vsplit")
    else
      vim.cmd("wincmd "..move_cmd[M.View.side])
    end
    vim.cmd("buffer "..curbuf)
    M.resize()
  end)
end

function M.win_open(opts)
  if opts and opts.any_tabpage then
    for _, v in pairs(M.View.tabpages) do
      if a.nvim_win_is_valid(v.winnr) then
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

local function get_width()
  if type(M.View.width) == "number" then
    return M.View.width
  end
  local width_as_number = tonumber(M.View.width:sub(0, -2))
  local percent_as_decimal = width_as_number / 100
  return math.floor(vim.o.columns * percent_as_decimal)
end

function M.resize()
  if not M.View.auto_resize or not a.nvim_win_is_valid(M.get_winnr()) then
    return
  end

  a.nvim_win_set_width(M.get_winnr(), get_width())
end

local move_tbl = {
  left = 'H',
  right = 'L',
  bottom = 'J',
  top = 'K',
}

-- TODO: remove this once they fix https://github.com/neovim/neovim/issues/14670
local function set_local(opt, value)
  local cmd
  if value == true then
    cmd = string.format('setlocal %s', opt)
  elseif value == false then
    cmd = string.format('setlocal no%s', opt)
  else
    cmd = string.format('setlocal %s=%s', opt, value)
  end
  vim.cmd(cmd)
end

function M.replace_window()
  local move_to = move_tbl[M.View.side]
  a.nvim_command("wincmd "..move_to)
  a.nvim_command("vertical resize "..get_width())
end

local function open_window()
  a.nvim_command("vsp")
  M.replace_window()
  local winnr = a.nvim_get_current_win()
  local tabpage = a.nvim_get_current_tabpage()
  M.View.tabpages[tabpage] = vim.tbl_extend("force", M.View.tabpages[tabpage] or {help = false}, {winnr = winnr})
end

local function is_buf_valid(bufnr)
  return a.nvim_buf_is_valid(bufnr) and a.nvim_buf_is_loaded(bufnr)
end

function M.open(options)
  if not is_buf_valid(M.View.bufnr) then
    create_buffer()
  end

  if not M.win_open() then
    open_window()
  end

  vim.cmd("buffer "..M.View.bufnr)
  for k, v in pairs(M.View.winopts) do
    set_local(k, v)
  end
  vim.cmd ":wincmd ="

	local opts = options or { focus_tree = true }
	if not opts.focus_tree then
		vim.cmd("wincmd p")
	end
end

local function get_existing_buffers()
  return vim.tbl_filter(
    function(buf)
      return a.nvim_buf_is_valid(buf) and vim.fn.buflisted(buf) == 1
    end,
    a.nvim_list_bufs()
  )
end

function M.close()
  if not M.win_open() then return end
  if #a.nvim_list_wins() == 1 then
    local existing_bufs = get_existing_buffers()
    if #existing_bufs > 0 then
      vim.cmd "sbnext"
    else
      vim.cmd "new"
    end
  end
  a.nvim_win_hide(M.get_winnr())
end

--- Returns the window number for nvim-tree within the tabpage specified
---@param tabpage number: (optional) the number of the chosen tabpage. Defaults to current tabpage.
---@return number
function M.get_winnr(tabpage)
  tabpage = tabpage or a.nvim_get_current_tabpage()
  local tabinfo = M.View.tabpages[tabpage]
  if tabinfo ~= nil then
    return tabinfo.winnr
  end
end

--- Checks if nvim-tree is displaying the help ui within the tabpage specified
---@param tabpage number: (optional) the number of the chosen tabpage. Defaults to current tabpage.
---@return number
function M.is_help_ui(tabpage)
  tabpage = tabpage or a.nvim_get_current_tabpage()
  local tabinfo = M.View.tabpages[tabpage]
  if tabinfo ~= nil then
    return tabinfo.help
  end
end

function M.toggle_help(tabpage)
  tabpage = tabpage or a.nvim_get_current_tabpage()
  M.View.tabpages[tabpage].help = not M.View.tabpages[tabpage].help
end

return M
