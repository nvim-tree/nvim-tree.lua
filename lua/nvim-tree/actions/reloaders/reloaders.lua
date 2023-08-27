local git = require "nvim-tree.git"
local view = require "nvim-tree.view"
local renderer = require "nvim-tree.renderer"
local explorer_module = require "nvim-tree.explorer"
local core = require "nvim-tree.core"
local explorer_node = require "nvim-tree.explorer.node"
local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {}

local function refresh_nodes(node, unloaded_bufnr)
  Iterator.builder({ node })
    :applier(function(n)
      if n.open and n.nodes then
        local project = git.get_project(n.cwd or n.link_to or n.absolute_path) or {}
        explorer_module.reload(n, project, unloaded_bufnr)
      end
    end)
    :recursor(function(n)
      return n.group_next and { n.group_next } or (n.open and n.nodes)
    end)
    :iterate()
end

function M.reload_node_status(parent_node)
  local project = git.get_project(parent_node.absolute_path) or {}
  for _, node in ipairs(parent_node.nodes) do
    explorer_node.update_git_status(node, explorer_node.is_git_ignored(parent_node), project)
    if node.nodes and #node.nodes > 0 then
      M.reload_node_status(node)
    end
  end
end

local event_running = false
---@param _ table|nil unused node passed by action
---@param unloaded_bufnr number|nil optional bufnr recently unloaded via BufUnload event
function M.reload_explorer(_, unloaded_bufnr)
  if event_running or not core.get_explorer() or vim.v.exiting ~= vim.NIL then
    return
  end
  event_running = true

  git.reload()
  refresh_nodes(core.get_explorer(), unloaded_bufnr)
  if view.is_visible() then
    renderer.draw(unloaded_bufnr)
  end
  event_running = false
end

function M.reload_git()
  if not core.get_explorer() or not git.config.git.enable or event_running then
    return
  end
  event_running = true

  git.reload()
  M.reload_node_status(core.get_explorer())
  renderer.draw()
  event_running = false
end

return M
