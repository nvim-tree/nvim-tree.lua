local a = vim.api

local M = {}

function M.nvim_tree_callback(callback_name)
  return string.format(":lua require'nvim-tree'.on_keypress('%s')<CR>", callback_name)
end

M.View = {
  bufnr = nil,
  tabpages = {},
  hide_root_folder = false,
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
      'StatusLine:NvimTreeStatusLine',
      'StatusLineNC:NvimTreeStatuslineNC',
      'SignColumn:NvimTreeSignColumn',
      'NormalNC:NvimTreeNormalNC',
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
    { key = "D",                            cb = M.nvim_tree_callback("trash") },
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
    { key = "g?",                           cb = M.nvim_tree_callback("toggle_help") },
    { key = 'm',                            cb = ":lua require'nvim-tree.marks'.toggle_mark()<cr>" },
    { key = 'M',                            cb = ":lua require'nvim-tree.marks'.disable_all()<cr>" },
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
    elseif b.cb then
      a.nvim_buf_set_keymap(M.View.bufnr, b.mode or 'n', b.key, b.cb, { noremap = true, silent = true, nowait = true })
    end
  end
end

local DEFAULT_CONFIG = {
  width = 30,
  height = 30,
  side = 'left',
  auto_resize = false,
  mappings = {
    custom_only = false,
    list = {}
  },
  number = false,
  relativenumber = false
}

local function merge_mappings(user_mappings)
  if #user_mappings == 0 then
    return M.View.mappings
  end

  local user_keys = {}
  for _, map in pairs(user_mappings) do
    if type(map.key) == "table" then
      for _, key in pairs(map.key) do
        table.insert(user_keys, key)
      end
    else
       table.insert(user_keys, map.key)
    end
  end

  local view_mappings = vim.tbl_filter(function(map)
    return not vim.tbl_contains(user_keys, map.key)
  end, M.View.mappings)

  return vim.fn.extend(view_mappings, user_mappings)
end

function M.setup(opts)
  local options = vim.tbl_deep_extend('force', DEFAULT_CONFIG, opts)
  M.View.side = options.side
  M.View.width = options.width
  M.View.height = options.height
  M.View.hide_root_folder = options.hide_root_folder
  M.View.auto_resize = opts.auto_resize
  M.View.winopts.number = options.number
  M.View.winopts.relativenumber = options.relativenumber
  if options.mappings.custom_only then
    M.View.mappings = options.mappings.list
  else
    M.View.mappings = merge_mappings(options.mappings.list)
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
      local cmd = M.is_vertical() and "vsplit" or "split"
      vim.cmd(cmd)
    else
      vim.cmd("wincmd "..move_cmd[M.View.side])
    end
    vim.cmd("buffer "..curbuf)
    M.resize()
    if vim.g.nvim_tree_quit_on_open == 1 then
      M.close()
    end
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

function M.is_vertical()
  return M.View.side == 'left' or M.View.side == 'right'
end

local function get_size()
  local width_or_height = M.is_vertical() and 'width' or 'height'
  local size = M.View[width_or_height]
  if type(size) == "number" then
    return size
  end
  local size_as_number = tonumber(size:sub(0, -2))
  local percent_as_decimal = size_as_number / 100
  return math.floor(vim.o.columns * percent_as_decimal)
end

function M.resize()
  if not M.View.auto_resize or not a.nvim_win_is_valid(M.get_winnr()) then
    return
  end

  if M.is_vertical() then
    a.nvim_win_set_width(M.get_winnr(), get_size())
  else
    a.nvim_win_set_height(M.get_winnr(), get_size())
  end
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
  local resize_direction = M.is_vertical() and 'vertical ' or ''
  a.nvim_command(resize_direction.."resize "..get_size())
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
  local should_redraw = false
  if not is_buf_valid(M.View.bufnr) then
    should_redraw = true
    create_buffer()
  end

  if not M.win_open() then
    open_window()
  end

  pcall(vim.cmd, "buffer "..M.View.bufnr)
  for k, v in pairs(M.View.winopts) do
    set_local(k, v)
  end
  vim.cmd ":wincmd ="

	local opts = options or { focus_tree = true }
	if not opts.focus_tree then
		vim.cmd("wincmd p")
	end
  return should_redraw
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
  if #a.nvim_list_wins() > 1 then
    a.nvim_win_hide(M.get_winnr())
  end
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
