local git_utils = require'nvim-tree.git.utils'
local Runner = require'nvim-tree.git.runner'

local M = {
  config = nil,
  projects = {},
  cwd_to_project_root = {}
}

function M.reload(callback)
  local num_projects = vim.tbl_count(M.projects)
  if not M.config.enable or num_projects == 0 then
    return callback({})
  end

  local done = 0
  for project_root in pairs(M.projects) do
    M.projects[project_root] = {}
    Runner.run {
      project_root = project_root,
      list_untracked = git_utils.should_show_untracked(project_root),
      list_ignored = M.config.ignore,
      timeout = M.config.timeout,
      on_end = function(git_status)
        M.projects[project_root] = {
          files = git_status,
          dirs = git_utils.file_status_to_dir_status(git_status, project_root)
        }
        done = done + 1
        if done == num_projects then
          callback(M.projects)
        end
      end
    }
  end
end

function M.get_project_root(cwd)
  if M.cwd_to_project_root[cwd] then
    return M.cwd_to_project_root[cwd]
  end

  if M.cwd_to_project_root[cwd] == false then
    return nil
  end

  local project_root = git_utils.get_toplevel(cwd)
  return project_root
end

function M.load_project_status(cwd, callback)
  if not M.config.enable then
    return callback({})
  end

  local project_root = M.get_project_root(cwd)
  if not project_root then
    M.cwd_to_project_root[cwd] = false
    return callback({})
  end

  local status = M.projects[project_root]
  if status then
    return callback(status)
  end

  Runner.run {
    project_root = project_root,
    list_untracked = git_utils.should_show_untracked(project_root),
    list_ignored = M.config.ignore,
    timeout = M.config.timeout,
    on_end = function(git_status)
      M.projects[project_root] = {
        files = git_status,
        dirs = git_utils.file_status_to_dir_status(git_status, project_root)
      }
      callback(M.projects[project_root])
    end
  }
end

function M.setup(opts)
  M.config = opts.git
end

return M
