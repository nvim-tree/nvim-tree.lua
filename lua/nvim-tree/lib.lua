local api = vim.api
local luv = vim.loop

local renderer = require'nvim-tree.renderer'
local diagnostics = require'nvim-tree.diagnostics'
local pops = require'nvim-tree.populate'
local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local events = require'nvim-tree.events'
local git = require'nvim-tree.git'
local populate = pops.populate
local refresh_entries = pops.refresh_entries

local first_init_done = false

local M = {}

M.Tree = {
  entries = {},
  cwd = nil,
  target_winid = nil,
}

local function load_children(cwd, children, parent)
  git.load_project_status(cwd, function(git_statuses)
    populate(children, cwd, parent, git_statuses)
    M.redraw()
  end)
end

function M.init(with_open, foldername)
  M.Tree.entries = {}
  M.Tree.cwd = foldername or luv.cwd()

  if with_open then
    M.open()
  end

  load_children(M.Tree.cwd, M.Tree.entries)

  if not first_init_done then
    events._dispatch_ready()
    first_init_done = true
  end
end

function M.redraw()
  renderer.draw(M.Tree, true)
end

local function get_node_at_line(line)
  local index = view.View.hide_root_folder and 1 or 2
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
      local n = M.get_last_group_node(entry)
      if node_path == n.absolute_path then
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
  local winnr = view.get_winnr()
  local hide_root_folder = view.View.hide_root_folder
  if not winnr then
    return
  end
  local cursor = api.nvim_win_get_cursor(view.get_winnr())
  local line = cursor[1]
  if view.is_help_ui() then
    local help_lines = require'nvim-tree.renderer.help'.compute_lines()
    local help_text = get_node_at_line(line+1)(help_lines)
    return {name = help_text}
  else
    if line == 1 and M.Tree.cwd ~= "/" and not hide_root_folder then
      return { name = ".." }
    end

    if M.Tree.cwd == "/" then
      line = line + 1
    end
    return get_node_at_line(line)(M.Tree.entries)
  end
end

-- If node is grouped, return the last node in the group. Otherwise, return the given node.
function M.get_last_group_node(node)
  local next = node
  while next.group_next do
    next = next.group_next
  end
  return next
end

function M.expand_or_collapse(node)
  node.open = not node.open
  if node.has_children then node.has_children = false end
  if #node.entries == 0 then
    load_children(
      node.link_to or node.absolute_path,
      node.entries,
      node
    )
  else
    M.redraw()
  end

  diagnostics.update()
end

local function refresh_nodes(node, projects)
  local project_root = git.get_project_root(node.absolute_path or node.cwd)
  refresh_entries(node.entries, node.absolute_path or node.cwd, node, projects[project_root] or {})
  for _, entry in ipairs(node.entries) do
    if entry.entries and entry.open then
      refresh_nodes(entry, projects)
    end
  end
end

local event_running = false
function M.refresh_tree()
  if event_running or not M.Tree.cwd or vim.v.exiting ~= vim.NIL then
    return
  end
  event_running = true

  git.reload(function(projects)
    refresh_nodes(M.Tree, projects)
    if view.win_open() then
      M.redraw()
    end
    diagnostics.update()
    event_running = false
  end)
end

local function reload_node_status(parent_node, projects)
  local project_root = git.get_project_root(parent_node.absolute_path or parent_node.cwd)
  local status = projects[project_root] or {}
  for _, node in ipairs(parent_node.entries) do
    if node.entries then
      node.git_status = status.dirs and status.dirs[node.absolute_path]
    else
      node.git_status = status.files and status.files[node.absolute_path]
    end
    if node.entries and #node.entries > 0 then
      reload_node_status(node, projects)
    end
  end
end

function M.reload_git()
  if not git.config.enable or event_running then
    return
  end
  event_running = true

  git.reload(function(projects)
    reload_node_status(M.Tree, projects)
    M.redraw()
    event_running = false
  end)
end

function M.set_index_and_redraw(fname)
  local i
  local hide_root_folder = view.View.hide_root_folder
  if M.Tree.cwd == '/' or hide_root_folder then
    i = 0
  else
    i = 1
  end

  local tree_altered = false

  local function iterate_nodes(nodes)
    for _, node in ipairs(nodes) do
      i = i + 1
      if node.absolute_path == fname then
        return i
      end

      local path_matches = utils.str_find(fname, node.absolute_path..utils.path_separator)
      if path_matches then
        if #node.entries == 0 then
          node.open = true
          populate(node.entries, node.absolute_path, node, {})
          git.load_project_status(node.absolute_path, function(status)
            if status.dirs or status.files then
              reload_node_status(node, git.projects)
            end
            M.redraw()
          end)
        end
        if node.open == false then
          node.open = true
          tree_altered = true
        end
        if iterate_nodes(node.entries) ~= nil then
          return i
        end
      elseif node.open == true then
        iterate_nodes(node.entries)
      end
    end
  end

  local index = iterate_nodes(M.Tree.entries)
  if tree_altered then
    M.redraw()
  end
  if index and view.win_open() then
    view.set_cursor({index, 0})
  end
end

function M.collapse_all()
  local function iter(nodes)
    for _, node in pairs(nodes) do
      if node.open then
        node.open = false
      end
      if node.entries then
        iter(node.entries)
      end
    end
  end

  iter(M.Tree.entries)
  M.redraw()
end

local current_tab = api.nvim_get_current_tabpage()

function M.change_dir(name)
  local foldername = name == '..' and vim.fn.fnamemodify(M.Tree.cwd, ':h') or name
  local no_cwd_change = vim.fn.expand(foldername) == M.Tree.cwd
  local new_tab = api.nvim_get_current_tabpage()
  local is_window = vim.v.event.scope == "window" and new_tab == current_tab
  if no_cwd_change or is_window then
    return
  end
  current_tab = new_tab

  if vim.g.nvim_tree_change_dir_global == 1 then
    vim.cmd('cd '..vim.fn.fnameescape(foldername))
  else
    vim.cmd('lcd '..vim.fn.fnameescape(foldername))
  end
  M.init(false, foldername)
end

function M.set_target_win()
  local id = api.nvim_get_current_win()
  local tree_id = view.get_winnr()
  if tree_id and id == tree_id then
    M.Tree.target_winid = 0
    return
  end

  M.Tree.target_winid = id
end

function M.open()
  M.set_target_win()

  local cwd = vim.fn.getcwd()
  local should_redraw = view.open()

  local respect_buf_cwd = vim.g.nvim_tree_respect_buf_cwd or 0
  if respect_buf_cwd == 1 and cwd ~= M.Tree.cwd then
    M.change_dir(cwd)
  end
  if should_redraw then
    M.redraw()
  end
end

function M.sibling(node, direction)
  if node.name == '..' or not direction then return end

  local iter = get_line_from_node(node, true)
  local node_path = node.absolute_path

  local line = 0
  local parent, _

  -- Check if current node is already at root entries
  for index, entry in ipairs(M.Tree.entries) do
    if node_path == entry.absolute_path then
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
end

function M.close_node(node)
  M.parent_node(node, true)
end

function M.parent_node(node, should_close)
  if node.name == '..' then return end

  should_close = should_close or false
  local altered_tree = false

  local iter = get_line_from_node(node, true)
  if node.open == true and should_close then
    node.open = false
    altered_tree = true
  else
    local line, parent = iter(M.Tree.entries, true)
    if parent == nil then
      line = 1
    elseif should_close then
      parent.open = false
      altered_tree = true
    end
    view.set_cursor({line, 0})
  end

  if altered_tree then
    M.redraw()
  end
end

function M.toggle_ignored()
  pops.config.filter_ignored = not pops.config.filter_ignored
  return M.refresh_tree()
end

function M.toggle_dotfiles()
  pops.config.filter_dotfiles = not pops.config.filter_dotfiles
  return M.refresh_tree()
end

function M.toggle_help()
  view.toggle_help()
  return M.redraw()
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
