local api = vim.api

local renderer = require'nvim-tree.renderer'
local diagnostics = require'nvim-tree.diagnostics'
local explorer = require'nvim-tree.explorer'
local view = require'nvim-tree.view'
local events = require'nvim-tree.events'

local first_init_done = false

local M = {
  target_winid = nil,
}

TreeExplorer = nil

function M.init(with_open, foldername)
  TreeExplorer = explorer.Explorer.new(foldername)
  TreeExplorer:init(function()
    if with_open then
      M.open()
    end
    if not first_init_done then
      events._dispatch_ready()
      first_init_done = true
    end
  end)
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
  if not TreeExplorer then return end
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
    if line == 1 and TreeExplorer.cwd ~= "/" and not hide_root_folder then
      return { name = ".." }
    end

    if TreeExplorer.cwd == "/" then
      line = line + 1
    end
    return get_node_at_line(line)(TreeExplorer.nodes)
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
    TreeExplorer:expand(node)
  else
    renderer.draw()
  end

  diagnostics.update()
end

function M.set_target_win()
  local id = api.nvim_get_current_win()
  local tree_id = view.get_winnr()
  if tree_id and id == tree_id then
    M.target_winid = 0
    return
  end

  M.target_winid = id
end

local function handle_buf_cwd(cwd)
  local respect_buf_cwd = vim.g.nvim_tree_respect_buf_cwd or 0
  if respect_buf_cwd == 1 and cwd ~= TreeExplorer.cwd then
    require'nvim-tree.actions.change-dir'.fn(cwd)
  end
end

local function open_view_and_draw()
  local cwd = vim.fn.getcwd()
  view.open()
  handle_buf_cwd(cwd)
  renderer.draw()
end

local function should_hijack_current_buf()
  local bufnr = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)
  local bufmodified = api.nvim_buf_get_option(bufnr, "modified")
  local ft = api.nvim_buf_get_option(bufnr, "ft")

  local should_hijack_unnamed = M.hijack_unnamed_buffer_when_opening
    and bufname == ""
    and not bufmodified
    and ft == ""
  local should_hijack_dir = bufname ~= ""
    and vim.fn.isdirectory(bufname) == 1
    and M.hijack_directories.enable

  return should_hijack_dir or should_hijack_unnamed
end

function M.open(cwd)
  M.set_target_win()
  if not TreeExplorer or cwd then
    return M.init(true, cwd or vim.loop.cwd())
  end
  if should_hijack_current_buf() then
    view.open_in_current_win()
    renderer.draw()
  else
    open_view_and_draw()
  end
end

-- @deprecated: use nvim-tree.actions.collapse-all.fn
M.collapse_all = require'nvim-tree.actions.collapse-all'.fn
-- @deprecated: use nvim-tree.actions.dir-up.fn
M.dir_up = require'nvim-tree.actions.dir-up'.fn
-- @deprecated: use nvim-tree.actions.change-dir.fn
M.change_dir = require'nvim-tree.actions.change-dir'.fn
-- @deprecated: use nvim-tree.actions.reloaders.reload_explorer
M.refresh_tree = require'nvim-tree.actions.reloaders'.reload_explorer
-- @deprecated: use nvim-tree.actions.reloaders.reload_git
M.reload_git = require'nvim-tree.actions.reloaders'.reload_git
-- @deprecated: use nvim-tree.actions.find-file.fn
M.set_index_and_redraw = require'nvim-tree.actions.find-file'.fn

function M.setup(opts)
  M.hijack_unnamed_buffer_when_opening = opts.hijack_unnamed_buffer_when_opening
  M.hijack_directories = opts.hijack_directories
end

return M
