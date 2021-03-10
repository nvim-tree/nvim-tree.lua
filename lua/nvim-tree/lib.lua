local api = vim.api
local luv = vim.loop

local renderer = require'nvim-tree.renderer'
local config = require'nvim-tree.config'
local git = require'nvim-tree.git'
local pops = require'nvim-tree.populate'
local utils = require'nvim-tree.utils'
local populate = pops.populate
local refresh_entries = pops.refresh_entries

local window_opts = config.window_options()

local M = {}

M.Tree = {
  entries = {},
  buf_name = 'NvimTree',
  cwd = nil,
  win_width =  vim.g.nvim_tree_width or 30,
  win_width_allow_resize = vim.g.nvim_tree_width_allow_resize,
  loaded = false,
  bufnr = nil,
  target_winid = nil,
  winnr = function()
    for _, i in ipairs(api.nvim_list_wins()) do
      if api.nvim_buf_get_name(api.nvim_win_get_buf(i)):match('.*'..utils.path_separator..M.Tree.buf_name..'$') then
        return i
      end
    end
  end,
  options = {
    'noswapfile',
    'norelativenumber',
    'nonumber',
    'nolist',
    'winfixwidth',
    'winfixheight',
    'nofoldenable',
    'nospell',
    'signcolumn=yes',
    'foldmethod=manual',
    'foldcolumn=0'
  }
}

function M.init(with_open, with_render)
  M.Tree.cwd = luv.cwd()
  populate(M.Tree.entries, M.Tree.cwd, M.Tree)

  local stat = luv.fs_stat(M.Tree.cwd)
  M.Tree.last_modified = stat.mtime.sec

  if with_open then
    M.open()
  end

  if with_render then
    renderer.draw(M.Tree, true)
    M.Tree.loaded = true
  end
end

local function get_node_at_line(line)
  local index = 2
  local function iter(entries)
    for _, node in ipairs(entries) do
      if index == line then
        return node
      end
      index = index + 1
      if node.open == true then
        local child = iter(node.entries)
        if child ~= nil then return child end
      end
    end
  end
  return iter
end

function M.get_node_at_cursor()
  local cursor = api.nvim_win_get_cursor(M.Tree.winnr())
  local line = cursor[1]
  if line == 1 and M.Tree.cwd ~= "/" then
    return { name = ".." }
  end

  if M.Tree.cwd == "/" then
    line = line + 1
  end
  return get_node_at_line(line)(M.Tree.entries)
end

function M.unroll_dir(node)
  node.open = not node.open
  if node.has_children then node.has_children = false end
  if #node.entries > 0 then
    renderer.draw(M.Tree, true)
  else
    populate(node.entries, node.link_to or node.absolute_path)
    renderer.draw(M.Tree, true)
  end
end

local function refresh_git(node)
  git.update_status(node.entries, node.absolute_path or node.cwd)
  for _, entry in pairs(node.entries) do
    if entry.entries ~= nil then
      refresh_git(entry)
    end
  end
end

-- TODO update only entries where directory has changed
local function refresh_nodes(node)
  refresh_entries(node.entries, node.absolute_path or node.cwd)
  for _, entry in ipairs(node.entries) do
    if entry.entries and entry.open then
      refresh_nodes(entry)
    end
  end
end

function M.refresh_tree()
  vim.schedule(
    function ()
      if vim.v.exiting ~= nil then return end

      refresh_nodes(M.Tree)

      if config.get_icon_state().show_git_icon or vim.g.nvim_tree_git_hl then
        git.reload_roots()
        refresh_git(M.Tree)
      end
      if M.win_open() then
        renderer.draw(M.Tree, true)
      else
        M.Tree.loaded = false
      end
    end)
end

function M.set_index_and_redraw(fname)
  local i
  if M.Tree.cwd == '/' then
    i = 0
  else
    i = 1
  end
  local reload = false

  local function iter(entries)
    for _, entry in ipairs(entries) do
      i = i + 1
      if entry.absolute_path == fname then
        return i
      end

      if fname:match(entry.match_path..'/') ~= nil then
        if #entry.entries == 0 then
          reload = true
          populate(entry.entries, entry.absolute_path)
        end
        if entry.open == false then
          reload = true
          entry.open = true
        end
        if iter(entry.entries) ~= nil then
          return i
        end
      elseif entry.open == true then
        iter(entry.entries)
      end
    end
  end

  local index = iter(M.Tree.entries)
  if not M.win_open() then
    M.Tree.loaded = false
    return
  end
  renderer.draw(M.Tree, reload)
  if index then
    api.nvim_win_set_cursor(M.Tree.winnr(), {index, 0})
  end
end

function M.open_file(mode, filename)
  local target_winnr = vim.fn.win_id2win(M.Tree.target_winid)
  local target_bufnr = target_winnr > 0 and vim.fn.winbufnr(M.Tree.target_winid)
  local splitcmd = window_opts.split_command == 'splitright' and 'vsplit' or 'split'
  local ecmd = target_bufnr and string.format('%dwindo %s', target_winnr, mode == 'preview' and 'edit' or mode) or (mode == 'preview' and 'edit' or mode)

  api.nvim_command('noautocmd wincmd '..window_opts.open_command)

  local found = false
  for _, win in ipairs(api.nvim_list_wins()) do
    if filename == api.nvim_buf_get_name(api.nvim_win_get_buf(win)) then
      found = true
      ecmd = function() M.win_focus(win) end
    end
  end

  if not found and (mode == 'edit' or mode == 'preview') then
    if target_bufnr then
      if not vim.o.hidden and api.nvim_buf_get_option(target_bufnr, 'modified') then
        ecmd = string.format('%dwindo %s', target_winnr, splitcmd)
      end
    else
      ecmd = splitcmd
    end
  end

  if type(ecmd) == 'string' then
    api.nvim_command(string.format('%s %s', ecmd, vim.fn.fnameescape(filename)))
  else
    ecmd()
  end

  if mode == 'preview' then
    if not found then M.set_target_win() end
    M.win_focus()
    return
  end

  if found then
    return
  end

  if not M.Tree.win_width_allow_resize then
    local cur_win = api.nvim_get_current_win()
    M.win_focus()
    api.nvim_command('vertical resize '..M.Tree.win_width)
    M.win_focus(cur_win)
  end
  if vim.g.nvim_tree_quit_on_open == 1 and mode ~= 'preview' then
    M.close()
  end
end

function M.change_dir(foldername)
  api.nvim_command('cd '..foldername)
  M.Tree.entries = {}
  M.init(false, M.Tree.bufnr ~= nil)
end

local function set_mapping(buf, key, cb)
  api.nvim_buf_set_keymap(buf, 'n', key, cb, {
    nowait = true, noremap = true, silent = true
  })
end

local function set_mappings()
  if vim.g.nvim_tree_disable_keybindings == 1 then
    return
  end

  local buf = M.Tree.bufnr
  local bindings = config.get_bindings()

  for key,cb in pairs(bindings) do
    set_mapping(buf, key, cb)
  end
end

local function create_buf()
  local options = {
    bufhidden = 'wipe';
    buftype = 'nofile';
    modifiable = false;
  }

  M.Tree.bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_name(M.Tree.bufnr, M.Tree.buf_name)

  for opt, val in pairs(options) do
    api.nvim_buf_set_option(M.Tree.bufnr, opt, val)
  end
  set_mappings()
end

local function create_win()
  api.nvim_command("vsplit")
  api.nvim_command("wincmd "..window_opts.side)
  api.nvim_command("vertical resize "..M.Tree.win_width)
end

function M.close()
  if #api.nvim_list_wins() == 1 then
    return vim.cmd ':q!'
  end
  api.nvim_win_close(M.Tree.winnr(), true)
  M.Tree.bufnr = nil
end

function M.set_target_win()
  M.Tree.target_winid = vim.fn.win_getid(vim.fn.bufwinnr(api.nvim_get_current_buf()))
end

function M.open()
  M.set_target_win()
  create_buf()
  create_win()
  api.nvim_win_set_buf(M.Tree.winnr(), M.Tree.bufnr)

  for _, opt in pairs(M.Tree.options) do
    api.nvim_command('setlocal '..opt)
  end

  if M.Tree.loaded then
    M.change_dir(vim.fn.getcwd())
  end
  renderer.draw(M.Tree, not M.Tree.loaded)
  M.Tree.loaded = true

  api.nvim_buf_set_option(M.Tree.bufnr, 'filetype', M.Tree.buf_name)
  api.nvim_command('setlocal '..window_opts.split_command)
end

function M.close_node(node)
  if node.name == '..' then return end

  local sep = package.config:sub(1,1)
  local dname = node.absolute_path:match("(.*"..sep..")")
  local index = 2

  local function iter(entries)
    for _, entry in ipairs(entries) do
      if dname:match('^'..entry.match_path..sep..'$') ~= nil then
        return entry
      end

      index = index + 1
      if entry.open == true then
        local child = iter(entry.entries)
        if child ~= nil then return child end
      end
    end
  end

  if node.open == true then
    node.open = false
  else
    local parent = iter(M.Tree.entries)
    if parent == nil then
      index = 1
    else
      parent.open = false
    end
    api.nvim_win_set_cursor(M.Tree.winnr(), {index, 0})
  end
  renderer.draw(M.Tree, true)
end

function M.win_open()
  return M.Tree.winnr() ~= nil
end

function M.win_focus(winnr)
  local wnr = winnr or M.Tree.winnr()

  if vim.api.nvim_win_get_tabpage(wnr) ~= vim.api.nvim_win_get_tabpage(0) then
    M.close()
    M.open()
    wnr = M.Tree.winnr()
  end

  api.nvim_set_current_win(wnr)
end

function M.toggle_ignored()
  pops.show_ignored = not pops.show_ignored
  return M.refresh_tree()
end

function M.toggle_dotfiles()
  pops.show_dotfiles = not pops.show_dotfiles
  return M.refresh_tree()
end

function M.dir_up(node)
  if not node then
    return M.change_dir('..')
  else
    local newdir = vim.fn.fnamemodify(M.Tree.cwd, ':h')
    M.change_dir(newdir)
    return M.set_index_and_redraw(node.absolute_path)
  end
end

return M
