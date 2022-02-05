local api = vim.api
local luv = vim.loop

local renderer = require'nvim-tree.renderer'
local diagnostics = require'nvim-tree.diagnostics'
local explorer = require'nvim-tree.explorer'
local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local events = require'nvim-tree.events'
local git = require'nvim-tree.git'

local first_init_done = false

local M = {}

M.Tree = {
  nodes = {},
  cwd = nil,
  target_winid = nil,
}

local function load_children(cwd, children, parent)
  git.load_project_status(cwd, function(git_statuses)
    explorer.explore(children, cwd, parent, git_statuses)
    M.redraw()
  end)
end

function M.init(with_open, foldername)
  M.Tree.nodes = {}
  M.Tree.cwd = foldername or luv.cwd()

  if with_open then
    M.open()
  end

  load_children(M.Tree.cwd, M.Tree.nodes)

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
  local function iter(nodes)
    for _, node in ipairs(nodes) do
      if index == line then
        return node
      end
      index = index + 1
      if node.open == true then
        local child = iter(node.nodes)
        if child ~= nil then return child end
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
    return get_node_at_line(line)(M.Tree.nodes)
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
  if #node.nodes == 0 then
    load_children(
      node.link_to or node.absolute_path,
      node.nodes,
      node
    )
  else
    M.redraw()
  end

  diagnostics.update()
end

local function refresh_nodes(node, projects)
  local project_root = git.get_project_root(node.absolute_path or node.cwd)
  explorer.refresh(node.nodes, node.absolute_path or node.cwd, node, projects[project_root] or {})
  for _, _node in ipairs(node.nodes) do
    if _node.nodes and _node.open then
      refresh_nodes(_node, projects)
    end
  end
end

local event_running = false
function M.refresh_tree(callback)
  if event_running or not M.Tree.cwd or vim.v.exiting ~= vim.NIL then
    return
  end
  event_running = true

  git.reload(function(projects)
    refresh_nodes(M.Tree, projects)
    if view.win_open() then
      M.redraw()
      if callback and type(callback) == 'function' then
        callback()
      end
    end
    diagnostics.update()
    event_running = false
  end)
end

local function reload_node_status(parent_node, projects)
  local project_root = git.get_project_root(parent_node.absolute_path or parent_node.cwd)
  local status = projects[project_root] or {}
  for _, node in ipairs(parent_node.nodes) do
    if node.nodes then
      node.git_status = status.dirs and status.dirs[node.absolute_path]
    else
      node.git_status = status.files and status.files[node.absolute_path]
    end
    if node.nodes and #node.nodes > 0 then
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
        if #node.nodes == 0 then
          node.open = true
          explorer.explore(node.nodes, node.absolute_path, node, {})
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
        if iterate_nodes(node.nodes) ~= nil then
          return i
        end
      elseif node.open == true then
        iterate_nodes(node.nodes)
      end
    end
  end

  local index = iterate_nodes(M.Tree.nodes)
  if tree_altered then
    M.redraw()
  end
  if index and view.win_open() then
    view.set_cursor({index, 0})
  end
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
    require'nvim-tree.actions.change-dir'.fn(cwd)
  end
  if should_redraw then
    M.redraw()
  end
end

function M.close_node(node)
  M.parent_node(node, true)
end

function M.toggle_ignored()
  explorer.config.filter_ignored = not explorer.config.filter_ignored
  return M.refresh_tree()
end

function M.toggle_dotfiles()
  explorer.config.filter_dotfiles = not explorer.config.filter_dotfiles
  return M.refresh_tree()
end

function M.toggle_help()
  view.toggle_help()
  return M.redraw()
end

-- @deprecated: use nvim-tree.actions.collapse-all.fn
M.collapse_all = require'nvim-tree.actions.collapse-all'.fn
-- @deprecated: use nvim-tree.actions.dir-up.fn
M.dir_up = require'nvim-tree.actions.dir-up'.fn
-- @deprecated: use nvim-tree.actions.change-dir.fn
M.change_dir = require'nvim-tree.actions.change-dir'.fn

return M
