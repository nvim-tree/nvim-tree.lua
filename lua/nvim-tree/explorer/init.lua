local core = require("nvim-tree.core")
local git = require("nvim-tree.git")
local log = require("nvim-tree.log")
local notify = require("nvim-tree.notify")
local utils = require("nvim-tree.utils")
local view = require("nvim-tree.view")
local node_factory = require("nvim-tree.node.factory")

local DirectoryNode = require("nvim-tree.node.directory")
local RootNode = require("nvim-tree.node.root")
local Watcher = require("nvim-tree.watcher")

local Iterator = require("nvim-tree.iterators.node-iterator")
local NodeIterator = require("nvim-tree.iterators.node-iterator")

local Filters = require("nvim-tree.explorer.filters")
local Marks = require("nvim-tree.marks")
local LiveFilter = require("nvim-tree.explorer.live-filter")
local Sorters = require("nvim-tree.explorer.sorters")
local Clipboard = require("nvim-tree.actions.fs.clipboard")
local Renderer = require("nvim-tree.renderer")

local FILTER_REASON = require("nvim-tree.enum").FILTER_REASON

local config

---@class (exact) Explorer: RootNode
---@field opts table user options
---@field renderer Renderer
---@field filters Filters
---@field live_filter LiveFilter
---@field sorters Sorter
---@field marks Marks
---@field clipboard Clipboard
local Explorer = RootNode:new()

---Static factory method
---@param path string?
---@return Explorer?
function Explorer:create(path)
  local err

  if path then
    path, err = vim.loop.fs_realpath(path)
  else
    path, err = vim.loop.cwd()
  end
  if not path then
    notify.error(err)
    return nil
  end

  ---@type Explorer
  local explorer_placeholder = nil

  local o = RootNode:create(explorer_placeholder, path, "..", nil)

  o = self:new(o) --[[@as Explorer]]

  o.explorer = o

  o.open = true
  o.opts = config

  o.sorters = Sorters:new(config)
  o.renderer = Renderer:new(config, o)
  o.filters = Filters:new(config, o)
  o.live_filter = LiveFilter:new(config, o)
  o.marks = Marks:new(config, o)
  o.clipboard = Clipboard:new(config, o)

  o:_load(o)

  return o
end

---@param node DirectoryNode
function Explorer:expand(node)
  self:_load(node)
end

---@param node DirectoryNode
---@param git_status table|nil
function Explorer:reload(node, git_status)
  local cwd = node.link_to or node.absolute_path
  local handle = vim.loop.fs_scandir(cwd)
  if not handle then
    return
  end

  local profile = log.profile_start("reload %s", node.absolute_path)

  local filter_status = self.filters:prepare(git_status)

  if node.group_next then
    node.nodes = { node.group_next }
    node.group_next = nil
  end

  local remain_childs = {}

  local node_ignored = node:is_git_ignored()
  ---@type table<string, Node>
  local nodes_by_path = utils.key_by(node.nodes, "absolute_path")

  -- To reset we must 'zero' everything that we use
  node.hidden_stats = vim.tbl_deep_extend("force", node.hidden_stats or {}, {
    git = 0,
    buf = 0,
    dotfile = 0,
    custom = 0,
    bookmark = 0,
  })

  while true do
    local name, _ = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local abs = utils.path_join({ cwd, name })
    ---@type uv.fs_stat.result|nil
    local stat = vim.loop.fs_lstat(abs)

    local filter_reason = self.filters:should_filter_as_reason(abs, stat, filter_status)
    if filter_reason == FILTER_REASON.none then
      remain_childs[abs] = true

      -- Recreate node if type changes.
      if nodes_by_path[abs] then
        local n = nodes_by_path[abs]

        if not stat or n.type ~= stat.type then
          utils.array_remove(node.nodes, n)
          n:destroy()
          nodes_by_path[abs] = nil
        end
      end

      if not nodes_by_path[abs] then
        local new_child = node_factory.create_node(self, node, abs, stat, name)
        if new_child then
          table.insert(node.nodes, new_child)
          nodes_by_path[abs] = new_child
        end
      else
        local n = nodes_by_path[abs]
        if n then
          n.executable = utils.is_executable(abs) or false
          n.fs_stat = stat
        end
      end
    else
      for reason, value in pairs(FILTER_REASON) do
        if filter_reason == value then
          node.hidden_stats[reason] = node.hidden_stats[reason] + 1
        end
      end
    end
  end

  node.nodes = vim.tbl_map(
    self:update_status(nodes_by_path, node_ignored, git_status),
    vim.tbl_filter(function(n)
      if remain_childs[n.absolute_path] then
        return remain_childs[n.absolute_path]
      else
        n:destroy()
        return false
      end
    end, node.nodes)
  )

  local single_child = node:single_child_directory()
  if config.renderer.group_empty and node.parent and single_child then
    node.group_next = single_child
    local ns = self:reload(single_child, git_status)
    node.nodes = ns or {}
    log.profile_end(profile)
    return ns
  end

  self.sorters:sort(node.nodes)
  self.live_filter:apply_filter(node)
  log.profile_end(profile)
  return node.nodes
end

---Refresh contents of all nodes to a path: actual directory and links.
---Groups will be expanded if needed.
---@param path string absolute path
function Explorer:refresh_parent_nodes_for_path(path)
  local profile = log.profile_start("refresh_parent_nodes_for_path %s", path)

  -- collect parent nodes from the top down
  local parent_nodes = {}
  NodeIterator.builder({ self })
    :recursor(function(node)
      return node.nodes
    end)
    :applier(function(node)
      local abs_contains = node.absolute_path and path:find(node.absolute_path, 1, true) == 1
      local link_contains = node.link_to and path:find(node.link_to, 1, true) == 1
      if abs_contains or link_contains then
        table.insert(parent_nodes, node)
      end
    end)
    :iterate()

  -- refresh in order; this will expand groups as needed
  for _, node in ipairs(parent_nodes) do
    local toplevel = git.get_toplevel(node.absolute_path)
    local project = git.get_project(toplevel) or {}

    self:reload(node, project)
    node:update_parent_statuses(project, toplevel)
  end

  log.profile_end(profile)
end

---@private
---@param node DirectoryNode
function Explorer:_load(node)
  local cwd = node.link_to or node.absolute_path
  local git_status = git.load_project_status(cwd)
  self:explore(node, git_status, self)
end

---@private
---@param nodes_by_path Node[]
---@param node_ignored boolean
---@param status table|nil
---@return fun(node: Node): table
function Explorer:update_status(nodes_by_path, node_ignored, status)
  return function(node)
    if nodes_by_path[node.absolute_path] then
      node:update_git_status(node_ignored, status)
    end
    return node
  end
end

---@private
---@param handle uv.uv_fs_t
---@param cwd string
---@param node DirectoryNode
---@param git_status table
---@param parent Explorer
function Explorer:populate_children(handle, cwd, node, git_status, parent)
  local node_ignored = node:is_git_ignored()
  local nodes_by_path = utils.bool_record(node.nodes, "absolute_path")

  local filter_status = parent.filters:prepare(git_status)

  node.hidden_stats = vim.tbl_deep_extend("force", node.hidden_stats or {}, {
    git = 0,
    buf = 0,
    dotfile = 0,
    custom = 0,
    bookmark = 0,
  })

  while true do
    local name, _ = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local abs = utils.path_join({ cwd, name })

    if Watcher.is_fs_event_capable(abs) then
      local profile = log.profile_start("populate_children %s", abs)

      ---@type uv.fs_stat.result|nil
      local stat = vim.loop.fs_lstat(abs)
      local filter_reason = parent.filters:should_filter_as_reason(abs, stat, filter_status)
      if filter_reason == FILTER_REASON.none and not nodes_by_path[abs] then
        local child = node_factory.create_node(self, node, abs, stat, name)
        if child then
          table.insert(node.nodes, child)
          nodes_by_path[child.absolute_path] = true
          child:update_git_status(node_ignored, git_status)
        end
      else
        for reason, value in pairs(FILTER_REASON) do
          if filter_reason == value then
            node.hidden_stats[reason] = node.hidden_stats[reason] + 1
          end
        end
      end

      log.profile_end(profile)
    end
  end
end

---@private
---@param node DirectoryNode
---@param status table
---@param parent Explorer
---@return Node[]|nil
function Explorer:explore(node, status, parent)
  local cwd = node.link_to or node.absolute_path
  local handle = vim.loop.fs_scandir(cwd)
  if not handle then
    return
  end

  local profile = log.profile_start("explore %s", node.absolute_path)

  self:populate_children(handle, cwd, node, status, parent)

  local is_root = not node.parent
  local single_child = node:single_child_directory()
  if config.renderer.group_empty and not is_root and single_child then
    local child_cwd = single_child.link_to or single_child.absolute_path
    local child_status = git.load_project_status(child_cwd)
    node.group_next = single_child
    local ns = self:explore(single_child, child_status, parent)
    node.nodes = ns or {}

    log.profile_end(profile)
    return ns
  end

  parent.sorters:sort(node.nodes)
  parent.live_filter:apply_filter(node)

  log.profile_end(profile)
  return node.nodes
end

---@private
---@param projects table
function Explorer:refresh_nodes(projects)
  Iterator.builder({ self })
    :applier(function(n)
      local dir = n:as(DirectoryNode)
      if dir then
        local toplevel = git.get_toplevel(dir.cwd or dir.link_to or dir.absolute_path)
        self:reload(dir, projects[toplevel] or {})
      end
    end)
    :recursor(function(n)
      return n.group_next and { n.group_next } or (n.open and n.nodes)
    end)
    :iterate()
end

local event_running = false
function Explorer:reload_explorer()
  if event_running or vim.v.exiting ~= vim.NIL then
    return
  end
  event_running = true

  local projects = git.reload()
  self:refresh_nodes(projects)
  if view.is_visible() then
    self.renderer:draw()
  end
  event_running = false
end

function Explorer:reload_git()
  if not git.config.git.enable or event_running then
    return
  end
  event_running = true

  local projects = git.reload()
  self:reload_node_status(projects)
  self.renderer:draw()
  event_running = false
end

---Cursor position as per vim.api.nvim_win_get_cursor
---nil on no explorer or invalid view win
---@return integer[]|nil
function Explorer:get_cursor_position()
  local winnr = view.get_winnr()
  if not winnr or not vim.api.nvim_win_is_valid(winnr) then
    return
  end

  return vim.api.nvim_win_get_cursor(winnr)
end

---@return Node|nil
function Explorer:get_node_at_cursor()
  local cursor = self:get_cursor_position()
  if not cursor then
    return
  end

  if cursor[1] == 1 and view.is_root_folder_visible(core.get_cwd()) then
    return self
  end

  return utils.get_nodes_by_line(self.nodes, core.get_nodes_starting_line())[cursor[1]]
end

---Api.tree.get_nodes
---@return Node
function Explorer:get_nodes()
  return self:clone()
end

function Explorer:setup(opts)
  config = opts
  require("nvim-tree.explorer.watch").setup(opts)
end

return Explorer
