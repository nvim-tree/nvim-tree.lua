local git = {} -- circular dependencies

local M = {}

---@param node Node
---@return GitStatus|nil
function M.get_git_status(node)
  local git_status = node and node.git_status
  if not git_status then
    -- status doesn't exist
    return nil
  end

  if not node.nodes then
    -- file
    return git_status.file and { git_status.file }
  end

  -- dir
  if not M.config.git.show_on_dirs then
    return nil
  end

  local status = {}
  if not require("nvim-tree.lib").get_last_group_node(node).open or M.config.git.show_on_open_dirs then
    -- dir is closed or we should show on open_dirs
    if git_status.file ~= nil then
      table.insert(status, git_status.file)
    end
    if git_status.dir ~= nil then
      if git_status.dir.direct ~= nil then
        for _, s in pairs(node.git_status.dir.direct) do
          table.insert(status, s)
        end
      end
      if git_status.dir.indirect ~= nil then
        for _, s in pairs(node.git_status.dir.indirect) do
          table.insert(status, s)
        end
      end
    end
  else
    -- dir is open and we shouldn't show on open_dirs
    if git_status.file ~= nil then
      table.insert(status, git_status.file)
    end
    if git_status.dir ~= nil and git_status.dir.direct ~= nil then
      local deleted = {
        [" D"] = true,
        ["D "] = true,
        ["RD"] = true,
        ["DD"] = true,
      }
      for _, s in pairs(node.git_status.dir.direct) do
        if deleted[s] then
          table.insert(status, s)
        end
      end
    end
  end
  if #status == 0 then
    return nil
  else
    return status
  end
end

---@param parent_node Node|nil
---@param projects table
function M.reload_node_status(parent_node, projects)
  if parent_node == nil then
    return
  end

  local toplevel = git.get_toplevel(parent_node.absolute_path)
  local status = projects[toplevel] or {}
  for _, node in ipairs(parent_node.nodes) do
    node:update_git_status(M.is_git_ignored(parent_node), status)
    if node.nodes and #node.nodes > 0 then
      M.reload_node_status(node, projects)
    end
  end
end

---@param node Node
function M.node_destroy(node)
  if not node then
    return
  end

  if node.watcher then
    node.watcher:destroy()
    node.watcher = nil
  end
end

function M.setup(opts)
  M.config = {
    git = opts.git,
  }

  git = require("nvim-tree.git")
end

return M
