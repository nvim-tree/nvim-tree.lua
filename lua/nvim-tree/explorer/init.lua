local builders = require "nvim-tree.explorer.node-builders"
local git = require "nvim-tree.git"
local log = require "nvim-tree.log"
local notify = require "nvim-tree.notify"
local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local watch = require "nvim-tree.explorer.watch"
local explorer_node = require "nvim-tree.explorer.node"

local Iterator = require "nvim-tree.iterators.node-iterator"
local NodeIterator = require "nvim-tree.iterators.node-iterator"
local Watcher = require "nvim-tree.watcher"

local Filters = require "nvim-tree.explorer.filters"
local Marks = require "nvim-tree.marks"
local LiveFilter = require "nvim-tree.explorer.live-filter"
local Sorters = require "nvim-tree.explorer.sorters"
local Clipboard = require "nvim-tree.actions.fs.clipboard"
local Renderer = require "nvim-tree.renderer"

local FILTER_REASON = require("nvim-tree.enum").FILTER_REASON

local config

---@class Explorer
---@field opts table user options
---@field absolute_path string
---@field nodes Node[]
---@field open boolean
---@field watcher Watcher|nil
---@field renderer Renderer
---@field filters Filters
---@field live_filter LiveFilter
---@field sorters Sorter
---@field marks Marks
---@field clipboard Clipboard
local Explorer = {}

---@param path string|nil
---@return Explorer|nil
function Explorer:new(path)
  local err

  if path then
    path, err = vim.loop.fs_realpath(path)
  else
    path, err = vim.loop.cwd()
  end
  if not path then
    notify.error(err)
    return
  end

  local o = {
    opts = config,
    absolute_path = path,
    nodes = {},
    open = true,
    sorters = Sorters:new(config),
  }

  setmetatable(o, self)
  self.__index = self

  o.watcher = watch.create_watcher(o)
  o.renderer = Renderer:new(config, o)
  o.filters = Filters:new(config, o)
  o.live_filter = LiveFilter:new(config, o)
  o.marks = Marks:new(config, o)
  o.clipboard = Clipboard:new(config, o)

  o:_load(o)

  return o
end

---@param node Node
function Explorer:expand(node)
  self:_load(node)
end

function Explorer:destroy()
  local function iterate(node)
    explorer_node.node_destroy(node)
    if node.nodes then
      for _, child in pairs(node.nodes) do
        iterate(child)
      end
    end
  end
  iterate(self)
end

---@param node Node
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

  local node_ignored = explorer_node.is_git_ignored(node)
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
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local abs = utils.path_join { cwd, name }
    ---@type uv.fs_stat.result|nil
    local stat = vim.loop.fs_stat(abs)

    local filter_reason = self.filters:should_filter_as_reason(abs, stat, filter_status)
    if filter_reason == FILTER_REASON.none then
      remain_childs[abs] = true

      -- Recreate node if type changes.
      if nodes_by_path[abs] then
        local n = nodes_by_path[abs]

        if n.type ~= t then
          utils.array_remove(node.nodes, n)
          explorer_node.node_destroy(n)
          nodes_by_path[abs] = nil
        end
      end

      if not nodes_by_path[abs] then
        local new_child = nil
        if t == "directory" and vim.loop.fs_access(abs, "R") and Watcher.is_fs_event_capable(abs) then
          new_child = builders.folder(node, abs, name, stat)
        elseif t == "file" then
          new_child = builders.file(node, abs, name, stat)
        elseif t == "link" then
          local link = builders.link(node, abs, name, stat)
          if link.link_to ~= nil then
            new_child = link
          end
        end
        if new_child then
          table.insert(node.nodes, new_child)
          nodes_by_path[abs] = new_child
        end
      else
        local n = nodes_by_path[abs]
        if n then
          n.executable = builders.is_executable(abs) or false
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
        explorer_node.node_destroy(n)
        return false
      end
    end, node.nodes)
  )

  local is_root = not node.parent
  local child_folder_only = explorer_node.has_one_child_folder(node) and node.nodes[1]
  if config.group_empty and not is_root and child_folder_only then
    node.group_next = child_folder_only
    local ns = self:reload(child_folder_only, git_status)
    node.nodes = ns or {}
    log.profile_end(profile)
    return ns
  end

  self.sorters:sort(node.nodes)
  self.live_filter:apply_filter(node)
  log.profile_end(profile)
  return node.nodes
end

---TODO #2837 #2871 move this and similar to node
---Refresh contents and git status for a single node
---@param node Node
---@param callback function
function Explorer:refresh_node(node, callback)
  if type(node) ~= "table" then
    callback()
  end

  local parent_node = utils.get_parent_of_group(node)

  self:reload_and_get_git_project(node.absolute_path, function(toplevel, project)
    self:reload(parent_node, project)

    self:update_parent_statuses(parent_node, project, toplevel)

    callback()
  end)
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
    self:update_parent_statuses(node, project, toplevel)
  end

  log.profile_end(profile)
end

---@private
---@param node Node
function Explorer:_load(node)
  local cwd = node.link_to or node.absolute_path
  local git_status = git.load_project_status(cwd)
  self:explore(node, git_status, self)
end

---@private
---@param nodes_by_path table
---@param node_ignored boolean
---@param status table|nil
---@return fun(node: Node): table
function Explorer:update_status(nodes_by_path, node_ignored, status)
  return function(node)
    if nodes_by_path[node.absolute_path] then
      explorer_node.update_git_status(node, node_ignored, status)
    end
    return node
  end
end

---TODO #2837 #2871 move this and similar to node
---@private
---@param path string
---@param callback fun(toplevel: string|nil, project: table|nil)
function Explorer:reload_and_get_git_project(path, callback)
  local toplevel = git.get_toplevel(path)

  git.reload_project(toplevel, path, function()
    callback(toplevel, git.get_project(toplevel) or {})
  end)
end

---TODO #2837 #2871 move this and similar to node
---@private
---@param node Node
---@param project table|nil
---@param root string|nil
function Explorer:update_parent_statuses(node, project, root)
  while project and node do
    -- step up to the containing project
    if node.absolute_path == root then
      -- stop at the top of the tree
      if not node.parent then
        break
      end

      root = git.get_toplevel(node.parent.absolute_path)

      -- stop when no more projects
      if not root then
        break
      end

      -- update the containing project
      project = git.get_project(root)
      git.reload_project(root, node.absolute_path, nil)
    end

    -- update status
    explorer_node.update_git_status(node, explorer_node.is_git_ignored(node.parent), project)

    -- maybe parent
    node = node.parent
  end
end

---@private
---@param handle uv.uv_fs_t
---@param cwd string
---@param node Node
---@param git_status table
---@param parent Explorer
function Explorer:populate_children(handle, cwd, node, git_status, parent)
  local node_ignored = explorer_node.is_git_ignored(node)
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
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local abs = utils.path_join { cwd, name }

    if Watcher.is_fs_event_capable(abs) then
      local profile = log.profile_start("populate_children %s", abs)

      ---@type uv.fs_stat.result|nil
      local stat = vim.loop.fs_stat(abs)
      local filter_reason = parent.filters:should_filter_as_reason(abs, stat, filter_status)
      if filter_reason == FILTER_REASON.none and not nodes_by_path[abs] then
        local child = nil
        if t == "directory" and vim.loop.fs_access(abs, "R") then
          child = builders.folder(node, abs, name, stat)
        elseif t == "file" then
          child = builders.file(node, abs, name, stat)
        elseif t == "link" then
          local link = builders.link(node, abs, name, stat)
          if link.link_to ~= nil then
            child = link
          end
        end
        if child then
          table.insert(node.nodes, child)
          nodes_by_path[child.absolute_path] = true
          explorer_node.update_git_status(child, node_ignored, git_status)
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
---@param node Node
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
  local child_folder_only = explorer_node.has_one_child_folder(node) and node.nodes[1]
  if config.renderer.group_empty and not is_root and child_folder_only then
    local child_cwd = child_folder_only.link_to or child_folder_only.absolute_path
    local child_status = git.load_project_status(child_cwd)
    node.group_next = child_folder_only
    local ns = self:explore(child_folder_only, child_status, parent)
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
      if n.nodes then
        local toplevel = git.get_toplevel(n.cwd or n.link_to or n.absolute_path)
        self:reload(n, projects[toplevel] or {})
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
  explorer_node.reload_node_status(self, projects)
  self.renderer:draw()
  event_running = false
end

function Explorer.setup(opts)
  config = opts
  require("nvim-tree.explorer.node").setup(opts)
  require("nvim-tree.explorer.watch").setup(opts)
end

return Explorer
