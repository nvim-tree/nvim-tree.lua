local luv = vim.loop
local api = vim.api

local lib = require'nvim-tree.lib'
local colors = require'nvim-tree.colors'
local renderer = require'nvim-tree.renderer'
local view = require'nvim-tree.view'
local utils = require'nvim-tree.utils'
local ChangeDir = require'nvim-tree.actions.change-dir'

local _config = {}

local M = {}

function M.focus()
  if not view.win_open() then
    lib.open()
  end
  view.focus();
end

---@deprecated
M.on_keypress = require'nvim-tree.actions'.on_keypress

function M.toggle(find_file)
  if view.win_open() then
    view.close()
  else
    if _config.update_focused_file.enable or find_file then
      M.find_file(true)
    end
    if not view.win_open() then
      lib.open()
    end
  end
end

function M.open()
  if not view.win_open() then
    lib.open()
  else
    lib.set_target_win()
  end
end

function M.tab_change()
  vim.schedule(function()
    if not view.win_open() and view.win_open({ any_tabpage = true }) then
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname:match("Neogit") ~= nil or bufname:match("--graph") ~= nil then
        return
      end
      view.open({ focus_tree = false })
    end
  end)
end

local function remove_empty_buffer()
  if not view.win_open() or #api.nvim_list_wins() ~= 1 then
    return
  end

  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    if api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf) then
      local name = api.nvim_buf_get_name(buf)
      if name == "" then
        api.nvim_buf_delete(buf, {})
      end
    end
  end
end

function M.hijack_current_window()
  local View = require'nvim-tree.view'.View
  if not View.bufnr then
    View.bufnr = api.nvim_get_current_buf()
  else
    api.nvim_buf_delete(api.nvim_get_current_buf(), { force = true })
  end
  local current_tab = api.nvim_get_current_tabpage()
  if not View.tabpages then
    View.tabpages = {
      [current_tab] = { winnr = api.nvim_get_current_win() }
    }
  else
    View.tabpages[current_tab] = { winnr = api.nvim_get_current_win() }
  end
  vim.defer_fn(remove_empty_buffer, 20)
end

function M.on_enter(netrw_disabled)
  local bufnr = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)
  local buftype = api.nvim_buf_get_option(bufnr, 'filetype')
  local ft_ignore = _config.ignore_ft_on_setup

  local stats = luv.fs_stat(bufname)
  local is_dir = stats and stats.type == 'directory'
  local cwd
  if is_dir then
    cwd = vim.fn.expand(bufname)
  end

  local lines = not is_dir and api.nvim_buf_get_lines(bufnr, 0, -1, false) or {}
  local buf_has_content = #lines > 1 or (#lines == 1 and lines[1] ~= "")

  local buf_is_dir = is_dir and netrw_disabled
  local buf_is_empty = bufname == "" and not buf_has_content
  local should_be_preserved = vim.tbl_contains(ft_ignore, buftype)
  local should_open = _config.open_on_setup and not should_be_preserved and (buf_is_dir or buf_is_empty)

  if should_open then
    M.hijack_current_window()
  end

  -- INFO: could potentially conflict with rooter plugins
  if cwd and should_open then
    vim.cmd("noautocmd cd "..cwd)
  end

  lib.init(should_open, cwd)
end

local function is_file_readable(fname)
  local stat = luv.fs_stat(fname)
  return stat and stat.type == "file" and luv.fs_access(fname, 'R')
end

local function update_base_dir_with_filepath(filepath, bufnr)
  if not _config.update_focused_file.update_cwd then
    return
  end

  local ft = api.nvim_buf_get_option(bufnr, 'filetype') or ""
  for _, value in pairs(_config.update_focused_file.ignore_list) do
    if utils.str_find(filepath, value) or utils.str_find(ft, value) then
      return
    end
  end

  if not vim.startswith(filepath, TreeExplorer.cwd or vim.loop.cwd()) then
    ChangeDir.fn(vim.fn.fnamemodify(filepath, ':p:h'))
  end
end

function M.find_file(with_open)
  local bufname = vim.fn.bufname()
  local bufnr = api.nvim_get_current_buf()
  local filepath = vim.fn.fnamemodify(bufname, ':p')
  if not is_file_readable(filepath) then
    return
  end

  if with_open then
    M.open()
    view.focus()
  end

  update_base_dir_with_filepath(filepath, bufnr)
  require"nvim-tree.actions.find-file".fn(filepath)
end

function M.resize(size)
  view.View.width = size
  view.View.height = size
  view.resize()
end

function M.on_leave()
  vim.defer_fn(function()
    if not view.win_open() then
      return
    end

    local windows = api.nvim_list_wins()
    local curtab = api.nvim_get_current_tabpage()
    local wins_in_tabpage = vim.tbl_filter(function(w)
      return api.nvim_win_get_tabpage(w) == curtab
    end, windows)
    if #windows == 1 then
      api.nvim_command(':silent qa!')
    elseif #wins_in_tabpage == 1 then
      api.nvim_command(':tabclose')
    end
  end, 50)
end

function M.open_on_directory()
  local should_proceed = _config.update_to_buf_dir.auto_open or view.win_open()
  if not _config.update_to_buf_dir.enable or not should_proceed then
    return
  end
  local buf = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(buf)
  if vim.fn.isdirectory(bufname) ~= 1 then
    return
  end

  view.close()
  if bufname ~= TreeExplorer.cwd  then
    ChangeDir.fn(bufname)
  end

  M.hijack_current_window()

  view.open()
  view.focus()
  view.replace_window()

  require"nvim-tree.actions.find-file".fn(bufname)
end

function M.reset_highlight()
  colors.setup()
  renderer.render_hl(view.View.bufnr)
end

local prev_line
function M.place_cursor_on_node()
  local l = vim.api.nvim_win_get_cursor(0)[1]
  if l == prev_line then
    return
  end
  prev_line = l

  local node = lib.get_node_at_cursor()
  if not node or node.name == ".." then
    return
  end

  local line = api.nvim_get_current_line()
  local cursor = api.nvim_win_get_cursor(0)
  local idx = vim.fn.stridx(line, node.name)

  if idx >= 0 then
    api.nvim_win_set_cursor(0, {cursor[1], idx})
  end
end

local function manage_netrw(disable_netrw, hijack_netrw)
  if hijack_netrw then
    vim.cmd "silent! autocmd! FileExplorer *"
  end
  if disable_netrw then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end
end

local function setup_vim_commands()
  vim.cmd [[
    command! NvimTreeOpen lua require'nvim-tree'.open()
    command! NvimTreeClose lua require'nvim-tree.view'.close()
    command! NvimTreeToggle lua require'nvim-tree'.toggle(false)
    command! NvimTreeFocus lua require'nvim-tree'.focus()
    command! NvimTreeRefresh lua require'nvim-tree.actions.reloaders'.reload_explorer()
    command! NvimTreeClipboard lua require'nvim-tree.actions.copy-paste'.print_clipboard()
    command! NvimTreeFindFile lua require'nvim-tree'.find_file(true)
    command! NvimTreeFindFileToggle lua require'nvim-tree'.toggle(true)
    command! -nargs=1 NvimTreeResize lua require'nvim-tree'.resize(<args>)
  ]]
end

function M.change_dir(name)
  ChangeDir.fn(name)

  if _config.update_focused_file.enable then
    M.find_file(false)
  end
end

local function setup_autocommands(opts)
  vim.cmd "augroup NvimTree"

  -- reset highlights when colorscheme is changed
  vim.cmd "au ColorScheme * lua require'nvim-tree'.reset_highlight()"
  vim.cmd "au BufWritePost * lua require'nvim-tree.actions.reloaders'.reload_explorer()"
  vim.cmd "au User FugitiveChanged,NeogitStatusRefreshed lua require'nvim-tree.actions.reloaders'.reload_git()"

  if opts.auto_close then
    vim.cmd "au WinClosed * lua require'nvim-tree'.on_leave()"
  end
  if opts.open_on_tab then
    vim.cmd "au TabEnter * lua require'nvim-tree'.tab_change()"
  end
  if opts.hijack_cursor then
    vim.cmd "au CursorMoved NvimTree lua require'nvim-tree'.place_cursor_on_node()"
  end
  if opts.update_cwd then
    vim.cmd "au DirChanged * lua require'nvim-tree'.change_dir(vim.loop.cwd())"
  end
  if opts.update_focused_file.enable then
    vim.cmd "au BufEnter * lua require'nvim-tree'.find_file(false)"
  end

  vim.cmd "au BufUnload NvimTree lua require'nvim-tree.view'.View.tabpages = {}"
  if not opts.actions.open_file.quit_on_open then
    vim.cmd "au BufWinEnter,BufWinLeave * lua require'nvim-tree.view'._prevent_buffer_override()"
  end
  vim.cmd "au BufEnter,BufNewFile * lua require'nvim-tree'.open_on_directory()"

  vim.cmd "augroup end"
end

local DEFAULT_OPTS = {
  disable_netrw       = true,
  hijack_netrw        = true,
  open_on_setup       = false,
  open_on_tab         = false,
  update_to_buf_dir   = {
    enable = true,
    auto_open = true,
  },
  auto_close          = false,
  hijack_cursor       = false,
  update_cwd          = false,
  hide_root_folder    = false,
  update_focused_file = {
    enable = false,
    update_cwd = false,
    ignore_list = {}
  },
  ignore_ft_on_setup = {},
  system_open = {
    cmd  = nil,
    args = {}
  },
  diagnostics = {
    enable = false,
    show_on_dirs = false,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    }
  },
  filters = {
    dotfiles = false,
    custom_filter = {},
    exclude = {}
  },
  git = {
    enable = true,
    ignore = true,
    timeout = 400,
  },
  actions = {
    change_dir = {
      global = vim.g.nvim_tree_change_dir_global == 1,
    },
    open_file = {
      quit_on_open = vim.g.nvim_tree_quit_on_open == 1,
    }
  }
}

function M.setup(conf)
  local opts = vim.tbl_deep_extend('force', DEFAULT_OPTS, conf or {})

  manage_netrw(opts.disable_netrw, opts.hijack_netrw)
  local netrw_disabled = opts.disable_netrw or opts.hijack_netrw

  _config.update_focused_file = opts.update_focused_file
  _config.open_on_setup = opts.open_on_setup
  _config.ignore_ft_on_setup = opts.ignore_ft_on_setup
  _config.update_to_buf_dir = opts.update_to_buf_dir
  _config.update_to_buf_dir.enable = _config.update_to_buf_dir.enable and netrw_disabled

  require'nvim-tree.colors'.setup()
  require'nvim-tree.actions'.setup(opts)
  require'nvim-tree.diagnostics'.setup(opts)
  require'nvim-tree.view'.setup(opts)
  require'nvim-tree.explorer'.setup(opts)
  require'nvim-tree.git'.setup(opts)
  setup_vim_commands()

  vim.schedule(function()
    M.on_enter(netrw_disabled)
    setup_autocommands(opts)
  end)
end

return M
