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
  if not M.Tree.cwd then
    M.Tree.cwd = luv.cwd()
  end
  git.git_root(M.Tree.cwd)
  populate(M.Tree.entries, M.Tree.cwd)

  local stat = luv.fs_stat(M.Tree.cwd)
  M.Tree.last_modified = stat.mtime.sec

  if with_open then
    M.open()
  elseif view.win_open() then
    M.refresh_tree()
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
    populate(node.entries, node.link_to or node.absolute_path, node)

    renderer.draw(M.Tree, true)
  end

  if vim.g.nvim_tree_lsp_diagnostics == 1 then
    diagnostics.update()
  end
end

local function refresh_git(node)
  if not node then node = M.Tree end
  git.update_status(node.entries, node.absolute_path or node.cwd, node)
  for _, entry in pairs(node.entries) do
    if entry.entries and #entry.entries > 0 then
      refresh_git(entry)
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
  if vim.v.exiting ~= vim.NIL then return end

  local use_git = config.use_git()
  if use_git then git.reload_roots() end
  refresh_nodes(M.Tree)
  if use_git then refresh_git(M.Tree) end

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

---Get user to pick a window. Selectable windows are all windows in the current
---tabpage that aren't NvimTree.
---@return integer|nil -- If a valid window was picked, return its id. If an
---       invalid window was picked / user canceled, return nil. If there are
---       no selectable windows, return -1.
function M.pick_window()
  local tabpage = api.nvim_get_current_tabpage()
  local win_ids = api.nvim_tabpage_list_wins(tabpage)
  local tree_winid = view.View.tabpages[tabpage]
  local exclude = config.window_picker_exclude()

  local selectable = vim.tbl_filter(function (id)
    local bufid = api.nvim_win_get_buf(id)
    for option, v in pairs(exclude) do
      local ok, option_value = pcall(api.nvim_buf_get_option, bufid, option)
      if ok and vim.tbl_contains(v, option_value) then
        return false
      end
    end

    local win_config = api.nvim_win_get_config(id)
    return id ~= tree_winid and win_config.focusable
  end, win_ids)

  -- If there are no selectable windows: return. If there's only 1, return it without picking.
  if #selectable == 0 then return -1 end
  if #selectable == 1 then return selectable[1] end

  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
  if vim.g.nvim_tree_window_picker_chars then
    chars = tostring(vim.g.nvim_tree_window_picker_chars):upper()
  end

  local i = 1
  local win_opts = {}
  local win_map = {}
  local laststatus = vim.o.laststatus
  vim.o.laststatus = 2

  -- Setup UI
  for _, id in ipairs(selectable) do
    local char = chars:sub(i, i)
    local ok_status, statusline = pcall(api.nvim_win_get_option, id, "statusline")
    local ok_hl, winhl = pcall(api.nvim_win_get_option, id, "winhl")

    win_opts[id] = {
      statusline = ok_status and statusline or "",
      winhl = ok_hl and winhl or ""
    }
    win_map[char] = id

    api.nvim_win_set_option(id, "statusline", "%=" .. char .. "%=")
    api.nvim_win_set_option(
      id, "winhl", "StatusLine:NvimTreeWindowPicker,StatusLineNC:NvimTreeWindowPicker"
    )

    i = i + 1
    if i > #chars then break end
  end

  vim.cmd("redraw")
  print("Pick window: ")
  local _, resp = pcall(utils.get_user_input_char)
  resp = (resp or ""):upper()
  utils.clear_prompt()

  -- Restore window options
  for _, id in ipairs(selectable) do
    for opt, value in pairs(win_opts[id]) do
      api.nvim_win_set_option(id, opt, value)
    end
  end

  vim.o.laststatus = laststatus

  return win_map[resp]
end

function M.open_file(mode, filename)
  if mode == "tabnew" then
    M.open_file_in_tab(filename)
    return
  end

  local tabpage = api.nvim_get_current_tabpage()
  local win_ids = api.nvim_tabpage_list_wins(tabpage)

  local target_winid
  if vim.g.nvim_tree_disable_window_picker == 1 then
    target_winid = M.Tree.target_winid
  else
    target_winid = M.pick_window()
  end

  if target_winid == -1 then
    target_winid = M.Tree.target_winid
  elseif target_winid == nil then
    return
  end

  local do_split = mode == "split" or mode == "vsplit"
  local vertical = mode ~= "split"

  -- Check if filename is already open in a window
  local found = false
  for _, id in ipairs(win_ids) do
    if filename == api.nvim_buf_get_name(api.nvim_win_get_buf(id)) then
      if mode == "preview" then return end
      found = true
      api.nvim_set_current_win(id)
      break
    end
  end

  if not found then
    if not target_winid or not vim.tbl_contains(win_ids, target_winid) then
      -- Target is invalid, or window does not exist in current tabpage: create
      -- new window
      vim.cmd(window_opts.split_command .. " vsp")
      target_winid = api.nvim_get_current_win()
      M.Tree.target_winid = target_winid

      -- No need to split, as we created a new window.
      do_split = false
    elseif not vim.o.hidden then
      -- If `hidden` is not enabled, check if buffer in target window is
      -- modified, and create new split if it is.
      local target_bufid = api.nvim_win_get_buf(target_winid)
      if api.nvim_buf_get_option(target_bufid, "modified") then
        do_split = true
      end
    end

    local cmd
    if do_split then
      cmd = string.format("%ssplit ", vertical and "vertical " or "")
    else
      cmd = "edit "
    end

    cmd = cmd .. vim.fn.fnameescape(filename)
    api.nvim_set_current_win(target_winid)
    vim.cmd(cmd)
    view.resize()
  end

  if mode == "preview" then
    view.focus()
    return
  end

  if vim.g.nvim_tree_quit_on_open == 1 then
    view.close()
  end

  renderer.draw(M.Tree, true)
end

function M.open_file_in_tab(filename)
  local close = vim.g.nvim_tree_quit_on_open == 1
  if close then
    view.close()
  else
    -- Switch window first to ensure new window doesn't inherit settings from
    -- NvimTree
    if M.Tree.target_winid > 0 and api.nvim_win_is_valid(M.Tree.target_winid) then
      api.nvim_set_current_win(M.Tree.target_winid)
    else
      vim.cmd("wincmd p")
    end
  end

  -- This sequence of commands are here to ensure a number of things: the new
  -- buffer must be opened in the current tabpage first so that focus can be
  -- brought back to the tree if it wasn't quit_on_open. It also ensures that
  -- when we open the new tabpage with the file, its window doesn't inherit
  -- settings from NvimTree, as it was already loaded.

  vim.cmd("edit " .. vim.fn.fnameescape(filename))

  local alt_bufid = vim.fn.bufnr("#")
  if alt_bufid ~= -1 then
    api.nvim_set_current_buf(alt_bufid)
  end

  if not close then
    vim.cmd("wincmd p")
  end

  vim.cmd("tabe " .. vim.fn.fnameescape(filename))
end

function M.change_dir(name)
  local changed_win = vim.v.event and vim.v.event.changed_window
  local foldername = name == '..' and vim.fn.fnamemodify(M.Tree.cwd, ':h') or name
  local no_cwd_change = vim.fn.expand(foldername) == M.Tree.cwd
  if changed_win or no_cwd_change then
    return
  end

  vim.cmd('lcd '..foldername)
  M.Tree.cwd = foldername
  M.Tree.entries = {}
  M.init(false, true)
end

function M.set_target_win()
  local id = api.nvim_get_current_win()
  local tree_id = view.View.tabpages[api.nvim_get_current_tabpage()]
  if tree_id and id == tree_id then
    M.Tree.target_winid = 0
    return
  end

  M.Tree.target_winid = id
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
  if not node or node.name == ".." then
    return M.change_dir('..')
  else
    local newdir = vim.fn.fnamemodify(M.Tree.cwd, ':h')
    M.change_dir(newdir)
    return M.set_index_and_redraw(node.absolute_path)
  end
end

return M
