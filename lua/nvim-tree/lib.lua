local api = vim.api
local luv = vim.loop

local renderer = require'nvim-tree.renderer'
local config = require'nvim-tree.config'
local git = require'nvim-tree.git'
local diagnostics = require'nvim-tree.diagnostics'
local pops = require'nvim-tree.populate'
local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local events = require'nvim-tree.events'
local populate = pops.populate
local refresh_entries = pops.refresh_entries

local first_init_done = false
local window_opts = config.window_options()

local M = {}

M.Tree = {
  entries = {},
  cwd = nil,
  loaded = false,
  target_winid = nil,
}

function M.init(with_open, with_reload)
  M.Tree.cwd = luv.cwd()
  git.git_root(M.Tree.cwd)
  git.update_gitignore_map_sync()
  populate(M.Tree.entries, M.Tree.cwd)

  local stat = luv.fs_stat(M.Tree.cwd)
  M.Tree.last_modified = stat.mtime.sec

  if with_open then
    M.open()
  end

  if with_reload then
    renderer.draw(M.Tree, true)
    M.Tree.loaded = true
  end

  if not first_init_done then
    events._dispatch_ready()
    first_init_done = true
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

local function get_line_from_node(node, find_parent)
  local node_path = node.absolute_path

  if find_parent then
    node_path = node.absolute_path:match("(.*)"..utils.path_separator)
  end

  local line = 2
  local function iter(entries, recursive)
    for _, entry in ipairs(entries) do
      if node_path:match('^'..entry.match_path..'$') ~= nil then
        return line, entry
      end

      line = line + 1
      if entry.open == true and recursive then
        local _, child = iter(entry.entries, recursive)
        if child ~= nil then return line, child end
      end
    end
  end
  return iter
end

function M.get_node_at_cursor()
  local cursor = api.nvim_win_get_cursor(view.get_winnr())
  local line = cursor[1]
  if line == 1 and M.Tree.cwd ~= "/" then
    return { name = ".." }
  end

  if M.Tree.cwd == "/" then
    line = line + 1
  end
  return get_node_at_line(line)(M.Tree.entries)
end

-- If node is grouped, return the last node in the group. Otherwise, return the given node.
function M.get_last_group_node(node)
  local next = node
  while next.group_next do
    next = next.group_next
  end
  return next
end

function M.unroll_dir(node)
  node.open = not node.open
  if node.has_children then node.has_children = false end
  if #node.entries > 0 then
    renderer.draw(M.Tree, true)
  else
    git.git_root(node.absolute_path)
    git.update_gitignore_map_sync()
    populate(node.entries, node.link_to or node.absolute_path, node)

    if vim.g.nvim_tree_lsp_diagnostics == 1 then
      diagnostics.update()
    end

    renderer.draw(M.Tree, true)
  end
end

local function refresh_git(node, update_gitignore)
  if not node then node = M.Tree end
  if update_gitignore == nil or update_gitignore == true then
    git.update_gitignore_map_sync()
  end
  git.update_status(node.entries, node.absolute_path or node.cwd, node)
  for _, entry in pairs(node.entries) do
    if entry.entries and #entry.entries > 0 then
      refresh_git(entry, false)
    end
  end
end

-- TODO update only entries where directory has changed
local function refresh_nodes(node)
  refresh_entries(node.entries, node.absolute_path or node.cwd, node)
  for _, entry in ipairs(node.entries) do
    if entry.entries and entry.open then
      refresh_nodes(entry)
    end
  end
end

function M.refresh_tree()
  if vim.v.exiting ~= nil then return end

  refresh_nodes(M.Tree)

  if config.get_icon_state().show_git_icon or vim.g.nvim_tree_git_hl == 1 then
    git.reload_roots()
    refresh_git(M.Tree)
  end

  if vim.g.nvim_tree_lsp_diagnostics == 1 then
    diagnostics.update()
  end

  if view.win_open() then
    renderer.draw(M.Tree, true)
  else
    M.Tree.loaded = false
  end
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

      if fname:match(entry.match_path..utils.path_separator) ~= nil then
        if #entry.entries == 0 then
          reload = true
          populate(entry.entries, entry.absolute_path, entry)
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
  if not view.win_open() then
    M.Tree.loaded = false
    return
  end
  renderer.draw(M.Tree, reload)
  if index then
    view.set_cursor({index, 0})
  end
end

function M.open_file(mode, filename)
  local target_winnr = vim.fn.win_id2win(M.Tree.target_winid)
  local target_bufnr = target_winnr > 0 and vim.fn.winbufnr(M.Tree.target_winid)
  local splitcmd = window_opts.split_command == 'splitright' and 'vsplit' or 'split'
  local ecmd = target_bufnr and string.format('%dwindo %s', target_winnr, mode == 'preview' and 'edit' or mode) or (mode == 'preview' and 'edit' or mode)

  api.nvim_command('wincmd '..window_opts.open_command)

  local found = false
  for _, win in ipairs(api.nvim_list_wins()) do
    if filename == api.nvim_buf_get_name(api.nvim_win_get_buf(win)) then
      found = true
      ecmd = function() view.focus(win) end
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

  view.resize()

  if mode == 'preview' then
    if not found then M.set_target_win() end
    view.focus()
    return
  end

  if found then
    return
  end

  if vim.g.nvim_tree_quit_on_open == 1 and mode ~= 'preview' then
    view.close()
  end

  renderer.draw(M.Tree, true)
end

function M.change_dir(foldername)
  if vim.fn.expand(foldername) == M.Tree.cwd then
    return
  end

  api.nvim_command('cd '..foldername)
  M.Tree.entries = {}
  M.init(false, true)
end

function M.set_target_win()
  M.Tree.target_winid = vim.fn.win_getid(vim.fn.bufwinnr(api.nvim_get_current_buf()))
end

function M.open()
  M.set_target_win()

  view.open()

  if M.Tree.loaded then
    M.change_dir(vim.fn.getcwd())
  end
  renderer.draw(M.Tree, not M.Tree.loaded)
  M.Tree.loaded = true
end

function M.sibling(node, direction)
  if not direction then return end

  local iter = get_line_from_node(node, true)
  local node_path = node.absolute_path

  local line, parent = 0, nil

  -- Check if current node is already at root entries
  for index, entry in ipairs(M.Tree.entries) do
    if node_path:match('^'..entry.match_path..'$') ~= nil then
      line = index
    end
  end

  if line > 0 then
    parent = M.Tree
  else
    _, parent = iter(M.Tree.entries, true)
    if parent ~= nil and #parent.entries > 1 then
      line, _ = get_line_from_node(node)(parent.entries)
    end

    -- Ignore parent line count
    line = line - 1
  end

  local index = line + direction
  if index < 1 then
    index = 1
  elseif index > #parent.entries then
    index = #parent.entries
  end
  local target_node = parent.entries[index]

  line, _ = get_line_from_node(target_node)(M.Tree.entries, true)
  view.set_cursor({line, 0})
  renderer.draw(M.Tree, true)
end

function M.close_node(node)
  M.parent_node(node, true)
end

function M.parent_node(node, should_close)
  if node.name == '..' then return end
  should_close = should_close or false

  local iter = get_line_from_node(node, true)
  if node.open == true and should_close then
    node.open = false
  else
    local line, parent = iter(M.Tree.entries, true)
    if parent == nil then
      line = 1
    elseif should_close then
      parent.open = false
    end
    api.nvim_win_set_cursor(view.get_winnr(), {line, 0})
  end
  renderer.draw(M.Tree, true)
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
