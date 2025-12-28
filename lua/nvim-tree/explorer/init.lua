local appearance = require("nvim-tree.appearance")
local buffers = require("nvim-tree.buffers")
local core = require("nvim-tree.core")
local git = require("nvim-tree.git")
local log = require("nvim-tree.log")
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
local Sorter = require("nvim-tree.explorer.sorter")
local Clipboard = require("nvim-tree.actions.fs.clipboard")
local Renderer = require("nvim-tree.renderer")

local FILTER_REASON = require("nvim-tree.enum").FILTER_REASON
local change_dir = require("nvim-tree.actions.root.change-dir")
local find_file = require("nvim-tree.actions.finders.find-file")

local config

---@class (exact) Explorer: RootNode
---@field uid_explorer number vim.loop.hrtime() at construction time
---@field opts table user options
---@field augroup_id integer
---@field renderer Renderer
---@field filters Filters
---@field live_filter LiveFilter
---@field sorters Sorter
---@field marks Marks
---@field clipboard Clipboard
local Explorer = RootNode:extend()

---@class Explorer
---@overload fun(args: ExplorerArgs): Explorer

---@class (exact) ExplorerArgs
---@field path string

---@protected
---@param args ExplorerArgs
function Explorer:new(args)
  Explorer.super.new(self, {
    explorer      = self,
    absolute_path = args.path,
    name          = "..",
  })

  self.uid_explorer = vim.loop.hrtime()
  self.augroup_id   = vim.api.nvim_create_augroup("NvimTree_Explorer_" .. self.uid_explorer, {})

  self.open         = true
  self.opts         = config

  self.sorters      = Sorter({ explorer = self })
  self.renderer     = Renderer({ explorer = self })
  self.filters      = Filters({ explorer = self })
  self.live_filter  = LiveFilter({ explorer = self })
  self.marks        = Marks({ explorer = self })
  self.clipboard    = Clipboard({ explorer = self })

  self:create_autocmds()

  self:_load(self)
end

function Explorer:destroy()
  log.line("dev", "Explorer:destroy")

  vim.api.nvim_del_augroup_by_id(self.augroup_id)

  RootNode.destroy(self)
end

function Explorer:create_autocmds()
  -- reset and draw (highlights) when colorscheme is changed
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = self.augroup_id,
    callback = function()
      appearance.setup()
      view.reset_winhl()
      self.renderer:draw()
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = self.augroup_id,
    callback = function()
      if self.opts.auto_reload_on_write and not self.opts.filesystem_watchers.enable then
        self:reload_explorer()
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = self.augroup_id,
    callback = function(data)
      -- only handle normal files
      if vim.bo[data.buf].buftype ~= "" then
        return
      end

      if self.filters.state.no_buffer then
        -- full reload is required to update the filter state
        utils.debounce("Buf:filter_buffer_" .. self.uid_explorer, self.opts.view.debounce_delay, function()
          self:reload_explorer()
        end)
      elseif self.opts.renderer.highlight_opened_files ~= "none" then
        -- draw to update opened highlight
        self.renderer:draw()
      end
    end,
  })

  -- update opened file buffers
  vim.api.nvim_create_autocmd("BufUnload", {
    group = self.augroup_id,
    callback = function(data)
      -- only handle normal files
      if vim.bo[data.buf].buftype ~= "" then
        return
      end

      if self.filters.state.no_buffer then
        -- full reload is required to update the filter state
        utils.debounce("Buf:filter_buffer_" .. self.uid_explorer, self.opts.view.debounce_delay, function()
          self:reload_explorer()
        end)
      elseif self.opts.renderer.highlight_opened_files ~= "none" then
        -- draw to update opened highlight; must be delayed as the buffer is still loaded during BufUnload
        vim.schedule(function()
          self.renderer:draw()
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = self.augroup_id,
    pattern = "NvimTree_*",
    callback = function()
      if utils.is_nvim_tree_buf(0) then
        if vim.fn.getcwd() ~= core.get_cwd() or (self.opts.reload_on_bufenter and not self.opts.filesystem_watchers.enable) then
          self:reload_explorer()
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = self.augroup_id,
    pattern = { "FugitiveChanged", "NeogitStatusRefreshed" },
    callback = function()
      if not self.opts.filesystem_watchers.enable and self.opts.git.enable then
        self:reload_git()
      end
    end,
  })

  if self.opts.hijack_cursor then
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = self.augroup_id,
      pattern = "NvimTree_*",
      callback = function()
        if utils.is_nvim_tree_buf(0) then
          self:place_cursor_on_node()
        end
      end,
    })
  end

  if self.opts.modified.enable then
    vim.api.nvim_create_autocmd({ "BufModifiedSet", "BufWritePost" }, {
      group = self.augroup_id,
      callback = function()
        utils.debounce("Buf:modified_" .. self.uid_explorer, self.opts.view.debounce_delay, function()
          buffers.reload_modified()
          self:reload_explorer()
        end)
      end,
    })
  end
end

---@param node DirectoryNode
function Explorer:expand_dir_node(node)
  self:_load(node)
end

---@param node DirectoryNode
---@param project GitProject?
---@return Node[]?
function Explorer:reload(node, project)
  local cwd = node.link_to or node.absolute_path
  local handle = vim.loop.fs_scandir(cwd)
  if not handle then
    return
  end

  local profile = log.profile_start("reload %s", node.absolute_path)

  local filter_status = self.filters:prepare(project)

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
    git      = 0,
    buf      = 0,
    dotfile  = 0,
    custom   = 0,
    bookmark = 0,
  })

  while true do
    local name, _ = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local abs = utils.path_join({ cwd, name })

    -- path incorrectly specified as an integer
    local stat = vim.loop.fs_lstat(abs) ---@diagnostic disable-line param-type-mismatch

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
        local new_child = node_factory.create({
          explorer      = self,
          parent        = node,
          absolute_path = abs,
          name          = name,
          fs_stat       = stat
        })
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
    self:update_git_statuses(nodes_by_path, node_ignored, project),
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
    local ns = self:reload(single_child, project)
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
    git.update_parent_projects(node, project, toplevel)
  end

  log.profile_end(profile)
end

---@private
---@param node DirectoryNode
function Explorer:_load(node)
  local cwd = node.link_to or node.absolute_path
  local project = git.load_project(cwd)
  self:explore(node, project, self)
end

---@private
---@param nodes_by_path Node[]
---@param node_ignored boolean
---@param project GitProject?
---@return fun(node: Node): Node
function Explorer:update_git_statuses(nodes_by_path, node_ignored, project)
  return function(node)
    if nodes_by_path[node.absolute_path] then
      node:update_git_status(node_ignored, project)
    end
    return node
  end
end

---@private
---@param handle uv.uv_fs_t
---@param cwd string
---@param node DirectoryNode
---@param project GitProject
---@param parent Explorer
function Explorer:populate_children(handle, cwd, node, project, parent)
  local node_ignored = node:is_git_ignored()
  local nodes_by_path = utils.bool_record(node.nodes, "absolute_path")

  local filter_status = parent.filters:prepare(project)

  node.hidden_stats = vim.tbl_deep_extend("force", node.hidden_stats or {}, {
    git      = 0,
    buf      = 0,
    dotfile  = 0,
    custom   = 0,
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

      -- path incorrectly specified as an integer
      local stat = vim.loop.fs_lstat(abs) ---@diagnostic disable-line param-type-mismatch

      local filter_reason = parent.filters:should_filter_as_reason(abs, stat, filter_status)
      if filter_reason == FILTER_REASON.none and not nodes_by_path[abs] then
        local child = node_factory.create({
          explorer      = self,
          parent        = node,
          absolute_path = abs,
          name          = name,
          fs_stat       = stat
        })
        if child then
          table.insert(node.nodes, child)
          nodes_by_path[child.absolute_path] = true
          child:update_git_status(node_ignored, project)
        end
      elseif node.hidden_stats then
        for reason, value in pairs(FILTER_REASON) do
          if filter_reason == value and type(node.hidden_stats[reason]) == "number" then
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
---@param project GitProject
---@param parent Explorer
---@return Node[]|nil
function Explorer:explore(node, project, parent)
  local cwd = node.link_to or node.absolute_path
  local handle = vim.loop.fs_scandir(cwd)
  if not handle then
    return
  end

  local profile = log.profile_start("explore %s", node.absolute_path)

  self:populate_children(handle, cwd, node, project, parent)

  local is_root = not node.parent
  local single_child = node:single_child_directory()
  if config.renderer.group_empty and not is_root and single_child then
    local child_cwd = single_child.link_to or single_child.absolute_path
    local child_project = git.load_project(child_cwd)
    node.group_next = single_child
    local ns = self:explore(single_child, child_project, parent)
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
---@param projects GitProject[]
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

  local projects = git.reload_all_projects()
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

  local projects = git.reload_all_projects()
  git.reload_node_status(self, projects)
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

  return self:get_nodes_by_line(core.get_nodes_starting_line())[cursor[1]]
end

function Explorer:place_cursor_on_node()
  local ok, search = pcall(vim.fn.searchcount)
  if ok and search and search.exact_match == 1 then
    return
  end

  local node = self:get_node_at_cursor()
  if not node or node.name == ".." then
    return
  end
  node = node:get_parent_of_group() or node

  local line = vim.api.nvim_get_current_line()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local idx = vim.fn.stridx(line, node.name)

  if idx >= 0 then
    vim.api.nvim_win_set_cursor(0, { cursor[1], idx })
  end
end

-- Find the line number of a node.
---@param node Node?
---@return integer -1 not found
function Explorer:find_node_line(node)
  if not node then
    return -1
  end

  local first_node_line = core.get_nodes_starting_line()
  local nodes_by_line = self:get_nodes_by_line(first_node_line)
  local iter_start, iter_end = first_node_line, #nodes_by_line

  for line = iter_start, iter_end, 1 do
    if nodes_by_line[line] == node then
      return line
    end
  end

  return -1
end

-- get the node in the tree state depending on the absolute path of the node
-- (grouped or hidden too)
---@param path string
---@return Node|nil
---@return number|nil
function Explorer:get_node_from_path(path)
  if self.absolute_path == path then
    return self
  end

  return Iterator.builder(self.nodes)
    :hidden()
    :matcher(function(node)
      return node.absolute_path == path or node.link_to == path
    end)
    :recursor(function(node)
      if node.group_next then
        return { node.group_next }
      end
      if node.nodes then
        return node.nodes
      end
    end)
    :iterate()
end

---Focus node passed as parameter if visible, otherwise focus first visible parent.
---If none of the parents is visible focus root.
---If node is nil do nothing.
---@param node Node? node to focus
function Explorer:focus_node_or_parent(node)
  while node do
    local found_node, i = self:find_node(function(node_)
      return node_.absolute_path == node.absolute_path
    end)

    if found_node or node.parent == nil then
      view.set_cursor({ i + 1, 1 })
      break
    end

    node = node.parent
  end
end

--- Get the node and index of the node from the tree that matches the predicate.
--- The explored nodes are those displayed on the view.
---@param fn fun(node: Node): boolean
---@return table|nil
---@return number
function Explorer:find_node(fn)
  local node, i = Iterator.builder(self.nodes)
    :matcher(fn)
    :recursor(function(node)
      return node.group_next and { node.group_next } or (node.open and #node.nodes > 0 and node.nodes)
    end)
    :iterate()
  i = view.is_root_folder_visible() and i or i - 1
  if node and node.explorer.live_filter.filter then
    i = i + 1
  end
  return node, i
end

--- Return visible nodes indexed by line
---@param line_start number
---@return table
function Explorer:get_nodes_by_line(line_start)
  local nodes_by_line = {}
  local line = line_start

  Iterator.builder(self.nodes)
    :applier(function(node)
      if node.group_next then
        return
      end
      nodes_by_line[line] = node
      line = line + 1
    end)
    :recursor(function(node)
      return node.group_next and { node.group_next } or (node.open and #node.nodes > 0 and node.nodes)
    end)
    :iterate()

  return nodes_by_line
end

---@param node Node
function Explorer:dir_up(node)
  if not node or node.name == ".." then
    change_dir.fn("..")
  else
    local cwd = core.get_cwd()
    if cwd == nil then
      return
    end

    local newdir = vim.fn.fnamemodify(utils.path_remove_trailing(cwd), ":h")
    change_dir.fn(newdir)
    find_file.fn(node.absolute_path)
  end
end

---Api.tree.get_nodes
---@return nvim_tree.api.Node
function Explorer:get_nodes()
  return self:clone()
end

---Expand the directory node or the root
---@param node Node
---@param expand_opts ApiTreeExpandOpts?
function Explorer:expand_all(node, expand_opts)
  if node then
    node:expand(expand_opts)
  else
    self.expand(self, expand_opts)
  end
end

---Expand the directory node or parent node
---@param node Node
---@param expand_opts ApiTreeExpandOpts?
function Explorer:expand_node(node, expand_opts)
  if not node then
    return
  end

  node:expand(expand_opts)
end

function Explorer:setup(opts)
  config = opts
end

return Explorer
