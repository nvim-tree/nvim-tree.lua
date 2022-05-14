local uv = vim.loop

local M = {}

local function get_dir_git_status(parent_ignored, status, absolute_path)
  if parent_ignored then
    return "!!"
  end
  local dir_status = status.dirs and status.dirs[absolute_path]
  local file_status = status.files and status.files[absolute_path]
  return dir_status or file_status
end

local function get_git_status(parent_ignored, status, absolute_path)
  return parent_ignored and "!!" or status.files and status.files[absolute_path]
end

function M.has_one_child_folder(node)
  return #node.nodes == 1 and node.nodes[1].nodes and uv.fs_access(node.nodes[1].absolute_path, "R")
end

function M.update_git_status(node, parent_ignored, status)
  -- status of the node's absolute path
  if node.nodes then
    node.git_status = get_dir_git_status(parent_ignored, status, node.absolute_path)
  else
    node.git_status = get_git_status(parent_ignored, status, node.absolute_path)
  end

  -- status of the link target, if the link itself is not dirty
  if node.link_to and not node.git_status then
    if node.nodes then
      node.git_status = get_dir_git_status(parent_ignored, status, node.link_to)
    else
      node.git_status = get_git_status(parent_ignored, status, node.link_to)
    end
  end
end

return M
