local M = {}

---@class GitStatus
---@field file string|nil
---@field dir table|nil

---@param parent_ignored boolean
---@param status table|nil
---@param absolute_path string
---@return GitStatus|nil
local function get_dir_git_status(parent_ignored, status, absolute_path)
  if parent_ignored then
    return { file = "!!" }
  end

  if status then
    return {
      file = status.files and status.files[absolute_path],
      dir = status.dirs and {
        direct = status.dirs.direct[absolute_path],
        indirect = status.dirs.indirect[absolute_path],
      },
    }
  end
end

---@param parent_ignored boolean
---@param status table
---@param absolute_path string
---@return GitStatus
local function get_git_status(parent_ignored, status, absolute_path)
  local file_status = parent_ignored and "!!" or status.files and status.files[absolute_path]
  return { file = file_status }
end

---@param node Node
---@return boolean
function M.has_one_child_folder(node)
  return #node.nodes == 1 and node.nodes[1].nodes and vim.loop.fs_access(node.nodes[1].absolute_path, "R") or false
end

---@param node Node
---@param parent_ignored boolean
---@param status table|nil
function M.update_git_status(node, parent_ignored, status)
  local get_status
  if node.nodes then
    get_status = get_dir_git_status
  else
    get_status = get_git_status
  end

  -- status of the node's absolute path
  node.git_status = get_status(parent_ignored, status, node.absolute_path)

  -- status of the link target, if the link itself is not dirty
  if node.link_to and not node.git_status then
    node.git_status = get_status(parent_ignored, status, node.link_to)
  end
end

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

---@param node Node
---@return boolean
function M.is_git_ignored(node)
  return node and node.git_status ~= nil and node.git_status.file == "!!"
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
end

return M
