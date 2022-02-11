local git = require "nvim-tree.git"
local diagnostics = require "nvim-tree.diagnostics"
local view = require "nvim-tree.view"
local renderer = require "nvim-tree.renderer"
local explorer_module = require'nvim-tree.explorer'

local M = {}

local function refresh_nodes(node, projects)
  local project_root = git.get_project_root(node.absolute_path or node.cwd)
  explorer_module.reload(node, node.absolute_path or node.cwd, projects[project_root] or {})
  for _, _node in ipairs(node.nodes) do
    if _node.nodes and _node.open then
      refresh_nodes(_node, projects)
    end
  end
end

function M.reload_node_status(parent_node, projects)
  local project_root = git.get_project_root(parent_node.absolute_path or parent_node.cwd)
  local status = projects[project_root] or {}
  for _, node in ipairs(parent_node.nodes) do
    if node.nodes then
      node.git_status = status.dirs and status.dirs[node.absolute_path]
    else
      node.git_status = status.files and status.files[node.absolute_path]
    end
    if node.nodes and #node.nodes > 0 then
      M.reload_node_status(node, projects)
    end
  end
end

local event_running = false
function M.reload_explorer(callback)
  if event_running or not TreeExplorer or not TreeExplorer.cwd or vim.v.exiting ~= vim.NIL then
    return
  end
  event_running = true

  git.reload(function(projects)
    refresh_nodes(TreeExplorer, projects)
    if view.win_open() then
      renderer.draw()
      if callback and type(callback) == 'function' then
        callback()
      end
    end
    diagnostics.update()
    event_running = false
  end)
end

function M.reload_git()
  if not TreeExplorer or not git.config.enable or event_running then
    return
  end
  event_running = true

  git.reload(function(projects)
    M.reload_node_status(TreeExplorer, projects)
    renderer.draw()
    event_running = false
  end)
end

return M
