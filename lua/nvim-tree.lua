local luv = vim.loop
local api = vim.api

local lib = require'nvim-tree.lib'
local config = require'nvim-tree.config'
local colors = require'nvim-tree.colors'
local renderer = require'nvim-tree.renderer'
local fs = require'nvim-tree.fs'
local view = require'nvim-tree.view'

local _config = {
  is_windows          = vim.fn.has('win32') == 1 or vim.fn.has('win32unix') == 1,
  is_macos            = vim.fn.has('mac') == 1 or vim.fn.has('macunix') == 1,
  is_unix             = vim.fn.has('unix') == 1,
  update_focused_file = {
    enable = false,
    update_cwd = false,
    ignore_list = {},
  },
  system_open         = {},
  ignore_ft_on_setup  = {},
  open_on_setup       = {},
}

local M = {}

function M.focus()
  if not view.win_open() then
    lib.open()
  end
  view.focus();
end

function M.toggle()
  if view.win_open() then
    view.close()
  else
    if _config.update_focused_file.enable then
      M.find_file(true)
    end
    if not view.win_open() then
      lib.open()
    end
  end
end

function M.close()
  if view.win_open() then
    view.close()
    return true
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

local function go_to(mode)
  local icon_state = config.get_icon_state()
  local flags = mode == 'prev_git_item' and 'b' or ''
  local icons = table.concat(vim.tbl_values(icon_state.icons.git_icons), '\\|')
  return function()
    return icon_state.show_git_icon and vim.fn.search(icons, flags)
  end
end

local keypress_funcs = {
  create = fs.create,
  remove = fs.remove,
  rename = fs.rename(false),
  full_rename = fs.rename(true),
  copy = fs.copy,
  copy_name = fs.copy_filename,
  copy_path = fs.copy_path,
  copy_absolute_path = fs.copy_absolute_path,
  cut = fs.cut,
  paste = fs.paste,
  close_node = lib.close_node,
  parent_node = lib.parent_node,
  toggle_ignored = lib.toggle_ignored,
  toggle_dotfiles = lib.toggle_dotfiles,
  toggle_help = lib.toggle_help,
  refresh = lib.refresh_tree,
  first_sibling = function(node) lib.sibling(node, -math.huge) end,
  last_sibling = function(node) lib.sibling(node, math.huge) end,
  prev_sibling = function(node) lib.sibling(node, -1) end,
  next_sibling = function(node) lib.sibling(node, 1) end,
  prev_git_item = go_to('prev_git_item'),
  next_git_item = go_to('next_git_item'),
  dir_up = lib.dir_up,
  close = function() M.close() end,
  preview = function(node)
    if node.entries ~= nil or node.name == '..' then return end
    return lib.open_file('preview', node.absolute_path)
  end,
  system_open = function(node)
    if not _config.system_open.cmd then
      if _config.is_windows then
        _config.system_open = {
          cmd = "cmd",
          args = {'/c', 'start', '""'}
        }
      elseif _config.is_macos then
        _config.system_open.cmd = 'open'
      elseif _config.is_linux then
        _config.system_open.cmd = 'xdg-open'
      else
        require'nvim-tree.utils'.echo_warning("Cannot open file with system application. Unrecognized platform.")
        return
      end
    end

    local process = {
      cmd = _config.system_open.cmd,
      args = _config.system_open.args,
      errors = '\n',
      stderr = luv.new_pipe(false)
    }
    table.insert(process.args, node.link_to or node.absolute_path)
    process.handle, process.pid = luv.spawn(process.cmd,
      { args = process.args, stdio = { nil, nil, process.stderr }},
      function(code)
        process.stderr:read_stop()
        process.stderr:close()
        process.handle:close()
        if code ~= 0 then
          process.errors = process.errors .. string.format('NvimTree system_open: return code %d.', code)
          error(process.errors)
        end
      end
    )
    if not process.handle then
      error("\n" .. process.pid .. "\nNvimTree system_open: failed to spawn process using '" .. process.cmd .. "'.")
      return
    end
    luv.read_start(process.stderr,
      function(err, data)
        if err then return end
        if data then process.errors = process.errors .. data end
      end
    )
  end,
}

function M.on_keypress(mode)
  if view.is_help_ui() and mode ~= 'toggle_help' then return end
  local node = lib.get_node_at_cursor()
  if not node then return end

  if keypress_funcs[mode] then
    return keypress_funcs[mode](node)
  end

  if node.name == ".." then
    return lib.change_dir("..")
  elseif mode == "cd" and node.entries ~= nil then
    return lib.change_dir(lib.get_last_group_node(node).absolute_path)
  elseif mode == "cd" then
    return
  end

  if node.link_to and not node.entries then
    lib.open_file(mode, node.link_to)
  elseif node.entries ~= nil then
    lib.unroll_dir(node)
  else
    lib.open_file(mode, node.absolute_path)
  end
end

function M.refresh()
  lib.refresh_tree()
end

function M.print_clipboard()
  fs.print_clipboard()
end

function M.hijack_current_window()
  local View = require'nvim-tree.view'.View
  if not View.bufnr then
    View.bufnr = api.nvim_get_current_buf()
  end
  local current_tab = api.nvim_get_current_tabpage()
  if not View.tabpages then
    View.tabpages = {
      [current_tab] = { winnr = api.nvim_get_current_win() }
    }
  else
    View.tabpages[current_tab] = { winnr = api.nvim_get_current_win() }
  end
end

function M.on_enter(opts)
  local bufnr = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)
  local buftype = api.nvim_buf_get_option(bufnr, 'filetype')
  local ft_ignore = _config.ignore_ft_on_setup

  local stats = luv.fs_stat(bufname)
  local is_dir = stats and stats.type == 'directory'
  if is_dir then
    lib.Tree.cwd = vim.fn.expand(bufname)
  end

  local netrw_disabled = opts.disable_netrw or opts.hijack_netrw

  local lines = not is_dir and api.nvim_buf_get_lines(bufnr, 0, -1, false) or {}
  local buf_has_content = #lines > 1 or (#lines == 1 and lines[1] ~= "")

  local should_open = _config.open_on_setup
    and ((is_dir and netrw_disabled) or (bufname == "" and not buf_has_content))
    and not vim.tbl_contains(ft_ignore, buftype)

  if should_open then
    M.hijack_current_window()
  end

  lib.init(should_open, should_open)
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
    if vim.fn.stridx(filepath, value) ~= -1 or vim.fn.stridx(ft, value) ~= -1 then
      return
    end
  end

  if not vim.startswith(filepath, lib.Tree.cwd or vim.loop.cwd()) then
    lib.change_dir(vim.fn.fnamemodify(filepath, ':p:h'))
  end
end

function M.find_file(with_open)
  local bufname = vim.fn.bufname()
  local bufnr = api.nvim_get_current_buf()
  local filepath = vim.fn.fnamemodify(bufname, ':p')

  if with_open then
    M.open()
    view.focus()
  end

  if not is_file_readable(filepath) then
    return
  end
  update_base_dir_with_filepath(filepath, bufnr)
  lib.set_index_and_redraw(filepath)
end

function M.resize(size)
  view.View.width = size
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
  local buf = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(buf)
  if vim.fn.isdirectory(bufname) ~= 1 or bufname == lib.Tree.cwd then
    return
  end

  if view.win_open() and #api.nvim_list_wins() > 1 then
    view.close()
  end
  M.hijack_current_window()
  lib.change_dir(bufname)
  lib.set_index_and_redraw(bufname)
  view.focus()
  view.replace_window()
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
  api.nvim_win_set_cursor(0, {cursor[1], idx})
end

local function manage_netrw(disable_netrw, hijack_netrw)
  if disable_netrw then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  elseif hijack_netrw then
    vim.cmd "silent! autocmd! FileExplorer *"
  end
end

local function setup_vim_commands()
  vim.cmd [[
    command! NvimTreeOpen lua require'nvim-tree'.open()
    command! NvimTreeClose lua require'nvim-tree'.close()
    command! NvimTreeToggle lua require'nvim-tree'.toggle()
    command! NvimTreeFocus lua require'nvim-tree'.focus()
    command! NvimTreeRefresh lua require'nvim-tree'.refresh()
    command! NvimTreeClipboard lua require'nvim-tree'.print_clipboard()
    command! NvimTreeFindFile lua require'nvim-tree'.find_file()
    command! -nargs=1 NvimTreeResize lua require'nvim-tree'.resize(<args>)
  ]]
end

local function setup_autocommands(opts)
  vim.cmd "augroup NvimTree"
  vim.cmd [[
    """ reset highlights when colorscheme is changed
    au ColorScheme * lua require'nvim-tree'.reset_highlight()

    au BufWritePost * lua require'nvim-tree'.refresh()
    au User FugitiveChanged,NeogitStatusRefreshed lua require'nvim-tree'.refresh()

    """ deletes the existing buffer when saved in a session to avoid conflicts
    au SessionLoadPost * lua require'nvim-tree.view'._wipe_rogue_buffer()
  ]]

  if vim.g.nvim_tree_lsp_diagnostics == 1 then
    vim.cmd "au User LspDiagnosticsChanged lua require'nvim-tree.diagnostics'.update()"
  end
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
    vim.cmd "au DirChanged * lua require'nvim-tree.lib'.change_dir(vim.loop.cwd())"
  end
  if opts.update_focused_file.enable then
    vim.cmd "au BufEnter * lua require'nvim-tree'.find_file(false)"
  end

  vim.cmd "augroup end"
end

local DEFAULT_OPTS = {
  disable_netrw       = true,
  hijack_netrw        = true,
  open_on_setup       = false,
  open_on_tab         = false,
  auto_close          = false,
  hijack_cursor       = false,
  update_cwd          = false,
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
}

function M.setup(conf)
  local opts = vim.tbl_deep_extend('force', DEFAULT_OPTS, conf or {})

  manage_netrw(opts.disable_netrw, opts.hijack_netrw)

  _config.update_focused_file = opts.update_focused_file
  _config.system_open = opts.system_open
  _config.open_on_setup = opts.open_on_setup
  _config.ignore_ft_on_setup = opts.ignore_ft_on_setup

  require'nvim-tree.colors'.setup()
  require'nvim-tree.view'.setup()

  setup_autocommands(opts)
  setup_vim_commands()

  -- scheduling to make sure current buffer has initialized before running buffer checks for auto open
  vim.schedule(function() M.on_enter(opts) end)
end

local out_config = {
  "nvim_tree_disable_netrw",
  "nvim_tree_hijack_netrw",
  "nvim_tree_auto_open",
  "nvim_tree_auto_close",
  "nvim_tree_tab_open",
  "nvim_tree_update_cwd",
  "nvim_tree_hijack_cursor",
  "nvim_tree_system_open_command",
  "nvim_tree_system_open_command_args",
  "nvim_tree_follow",
  "nvim_tree_follow_update_path",
}

local x = vim.tbl_filter(function(v)
  return vim.fn.exists('g:'..v) ~= 0
end, out_config)

if #x > 0 then
  local msg = "following options are now set in the setup, please read the new documentation for the setup function: "
  require'nvim-tree.utils'.echo_warning(msg..table.concat(x, " | "))
end

return M
