local git = require "nvim-tree.git"
local view = require "nvim-tree.view"
local renderer = require "nvim-tree.renderer"
local explorer_module = require "nvim-tree.explorer"
local core = require "nvim-tree.core"
local explorer_node = require "nvim-tree.explorer.node"

local M = {}

local function refresh_nodes(node, projects, unloaded_bufnr)
  local cwd = node.cwd or node.link_to or node.absolute_path
  local project_root = git.get_project_root(cwd)
  explorer_module.reload(node, projects[project_root] or {}, unloaded_bufnr)
  for _, _node in ipairs(node.nodes) do
    if _node.nodes and _node.open then
      refresh_nodes(_node, projects, unloaded_bufnr)
    end
  end
end

function M.reload_node_status(parent_node, projects)
  local project_root = git.get_project_root(parent_node.absolute_path)
  local status = projects[project_root] or {}
  for _, node in ipairs(parent_node.nodes) do
    explorer_node.update_git_status(node, explorer_node.is_git_ignored(parent_node), status)
    if node.nodes and #node.nodes > 0 then
      M.reload_node_status(node, projects)
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

  local projects = git.reload()
  refresh_nodes(core.get_explorer(), projects, unloaded_bufnr)
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

  local projects = git.reload()
  M.reload_node_status(core.get_explorer(), projects)
  renderer.draw()
  event_running = false
end

return M
