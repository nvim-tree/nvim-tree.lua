local renderer = require "nvim-tree.renderer"
local view = require "nvim-tree.view"
local core = require "nvim-tree.core"
local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local explorer_node = require "nvim-tree.explorer.node"

---@class LibOpenOpts
---@field path string|nil path
---@field current_window boolean|nil default false
---@field winid number|nil

local M = {
  target_winid = nil,
}

---@return Node|nil
function M.get_node_at_cursor()
  if not core.get_explorer() then
    return
  end

  local winnr = view.get_winnr()
  if not winnr then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local line = cursor[1]

  if line == 1 and view.is_root_folder_visible(core.get_cwd()) then
    return { name = ".." }
  end

  return utils.get_nodes_by_line(core.get_explorer().nodes, core.get_nodes_starting_line())[line]
end

---Create a sanitized partial copy of a node, populating children recursively.
---@param node Node|nil
---@return Node|nil cloned node
local function clone_node(node)
  if not node then
    node = core.get_explorer()
    if not node then
      return nil
    end
  end

  local n = {
    absolute_path = node.absolute_path,
    executable = node.executable,
    extension = node.extension,
    git_status = node.git_status,
    has_children = node.has_children,
    hidden = node.hidden,
    link_to = node.link_to,
    name = node.name,
    open = node.open,
    type = node.type,
  }

  if type(node.nodes) == "table" then
    n.nodes = {}
    for _, child in ipairs(node.nodes) do
      table.insert(n.nodes, clone_node(child))
    end
  end

  return n
end

---Api.tree.get_nodes
---@return Node[]|nil
function M.get_nodes()
  return clone_node(core.get_explorer())
end

-- If node is grouped, return the last node in the group. Otherwise, return the given node.
---@param node Node
---@return Node
function M.get_last_group_node(node)
  while node and node.group_next do
    node = node.group_next
  end

  ---@diagnostic disable-next-line: return-type-mismatch -- it can't be nil
  return node
end

---Group empty folders
-- Recursively group nodes
---@param node Node
---@return Node[]
function M.group_empty_folders(node)
  local is_root = not node.parent
  local child_folder_only = explorer_node.has_one_child_folder(node) and node.nodes[1]
  if M.group_empty and not is_root and child_folder_only then
    node.group_next = child_folder_only
    local ns = M.group_empty_folders(child_folder_only)
    node.nodes = ns or {}
    return ns
  end
  return node.nodes
end

---Ungroup empty folders
-- If a node is grouped, ungroup it: put node.group_next to the node.nodes and set node.group_next to nil
---@param node Node
function M.ungroup_empty_folders(node)
  local cur = node
  while cur and cur.group_next do
    cur.nodes = { cur.group_next }
    cur.group_next = nil
    cur = cur.nodes[1]
  end
end

---@param node Node
---@return Node[]
function M.get_all_nodes_in_group(node)
  local next_node = utils.get_parent_of_group(node)
  local nodes = {}
  while next_node do
    table.insert(nodes, next_node)
    next_node = next_node.group_next
  end
  return nodes
end

-- Toggle group empty folders
---@param head_node Node
local function toggle_group_folders(head_node)
  local is_grouped = head_node.group_next ~= nil

  if is_grouped then
    M.ungroup_empty_folders(head_node)
  else
    M.group_empty_folders(head_node)
  end
end

---@param node Node
function M.expand_or_collapse(node, toggle_group)
  toggle_group = toggle_group or false
  if node.has_children then
    node.has_children = false
  end

  if #node.nodes == 0 then
    core.get_explorer():expand(node)
  end

  local head_node = utils.get_parent_of_group(node)
  if toggle_group then
    toggle_group_folders(head_node)
  end

  local open = M.get_last_group_node(node).open
  local next_open
  if toggle_group then
    next_open = open
  else
    next_open = not open
  end
  for _, n in ipairs(M.get_all_nodes_in_group(head_node)) do
    n.open = next_open
  end

  renderer.draw()
end

function M.set_target_win()
  local id = vim.api.nvim_get_current_win()
  local tree_id = view.get_winnr()
  if tree_id and id == tree_id then
    M.target_winid = 0
    return
  end

  M.target_winid = id
end

---@param cwd string
local function handle_buf_cwd(cwd)
  if M.respect_buf_cwd and cwd ~= core.get_cwd() then
    require("nvim-tree.actions.root.change-dir").fn(cwd)
  end
end

local function open_view_and_draw()
  local cwd = vim.fn.getcwd()
  view.open()
  handle_buf_cwd(cwd)
  renderer.draw()
end

local function should_hijack_current_buf()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local bufmodified = vim.api.nvim_buf_get_option(bufnr, "modified")
  local ft = vim.api.nvim_buf_get_option(bufnr, "ft")

  local should_hijack_unnamed = M.hijack_unnamed_buffer_when_opening and bufname == "" and not bufmodified and ft == ""
  local should_hijack_dir = bufname ~= "" and vim.fn.isdirectory(bufname) == 1 and M.hijack_directories.enable

  return should_hijack_dir or should_hijack_unnamed
end

---@param prompt_input string
---@param prompt_select string
---@param items_short string[]
---@param items_long string[]
---@param kind string|nil
---@param callback fun(item_short: string)
function M.prompt(prompt_input, prompt_select, items_short, items_long, kind, callback)
  local function format_item(short)
    for i, s in ipairs(items_short) do
      if short == s then
        return items_long[i]
      end
    end
    return ""
  end

  if M.select_prompts then
    vim.ui.select(items_short, { prompt = prompt_select, kind = kind, format_item = format_item }, function(item_short)
      callback(item_short)
    end)
  else
    vim.ui.input({ prompt = prompt_input, default = items_short[1] or "" }, function(item_short)
      if item_short then
        callback(string.lower(item_short and item_short:sub(1, 1)) or nil)
      end
    end)
  end
end

---Open the tree, initialising as needed. Maybe hijack the current buffer.
---@param opts LibOpenOpts|nil
function M.open(opts)
  opts = opts or {}

  M.set_target_win()
  if not core.get_explorer() or opts.path then
    core.init(opts.path or vim.loop.cwd())
  end
  if should_hijack_current_buf() then
    view.close_this_tab_only()
    view.open_in_win()
    renderer.draw()
  elseif opts.winid then
    view.open_in_win { hijack_current_buf = false, resize = false, winid = opts.winid }
    renderer.draw()
  elseif opts.current_window then
    view.open_in_win { hijack_current_buf = false, resize = false }
    renderer.draw()
  else
    open_view_and_draw()
  end
  view.restore_tab_state()
  events._dispatch_on_tree_open()
end

function M.setup(opts)
  M.hijack_unnamed_buffer_when_opening = opts.hijack_unnamed_buffer_when_opening
  M.hijack_directories = opts.hijack_directories
  M.respect_buf_cwd = opts.respect_buf_cwd
  M.select_prompts = opts.select_prompts
  M.group_empty = opts.renderer.group_empty
end

return M
