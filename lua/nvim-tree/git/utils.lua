local log = require("nvim-tree.log")
local utils = require("nvim-tree.utils")

local M = {
  use_cygpath = false,
}

--- Retrieve the git toplevel directory
---@param cwd string path
---@return string|nil toplevel absolute path
---@return string|nil git_dir absolute path
function M.get_toplevel(cwd)
  local profile = log.profile_start("git toplevel git_dir %s", cwd)

  -- both paths are absolute
  local cmd = { "git", "-C", cwd, "rev-parse", "--show-toplevel", "--absolute-git-dir" }
  log.line("git", "%s", table.concat(cmd, " "))

  local out = vim.fn.system(cmd)

  log.raw("git", out)
  log.profile_end(profile)

  if vim.v.shell_error ~= 0 or not out or #out == 0 or out:match("fatal") then
    return nil, nil
  end

  local toplevel, git_dir = out:match("([^\n]+)\n+([^\n]+)")
  if not toplevel then
    return nil, nil
  end
  if not git_dir then
    git_dir = utils.path_join({ toplevel, ".git" })
  end

  -- git always returns path with forward slashes
  if vim.fn.has("win32") == 1 then
    -- msys2 git support
    -- cygpath calls must in array format to avoid shell compatibility issues
    if M.use_cygpath then
      toplevel = vim.fn.system({ "cygpath", "-w", toplevel })
      if vim.v.shell_error ~= 0 then
        return nil, nil
      end
      -- remove trailing newline(\n) character added by vim.fn.system
      toplevel = toplevel:gsub("\n", "")
      git_dir = vim.fn.system({ "cygpath", "-w", git_dir })
      if vim.v.shell_error ~= 0 then
        return nil, nil
      end
      -- remove trailing newline(\n) character added by vim.fn.system
      git_dir = git_dir:gsub("\n", "")
    end
    toplevel = toplevel:gsub("/", "\\")
    git_dir = git_dir:gsub("/", "\\")
  end

  return toplevel, git_dir
end

---@type table<string, boolean>
local untracked = {}

---@param cwd string
---@return boolean
function M.should_show_untracked(cwd)
  if untracked[cwd] ~= nil then
    return untracked[cwd]
  end

  local profile = log.profile_start("git untracked %s", cwd)

  local cmd = { "git", "-C", cwd, "config", "status.showUntrackedFiles" }
  log.line("git", table.concat(cmd, " "))

  local has_untracked = vim.fn.system(cmd)

  log.raw("git", has_untracked)
  log.profile_end(profile)

  untracked[cwd] = vim.trim(has_untracked) ~= "no"
  return untracked[cwd]
end

---@param t table<string|integer, boolean>?
---@param k string|integer
---@return table
local function nil_insert(t, k)
  t = t or {}
  t[k] = true
  return t
end

---@param project_files GitProjectFiles
---@param cwd string|nil
---@return GitProjectDirs
function M.project_files_to_project_dirs(project_files, cwd)
  ---@type GitProjectDirs
  local project_dirs = {}

  project_dirs.direct = {}
  for p, s in pairs(project_files) do
    if s ~= "!!" then
      local modified = vim.fn.fnamemodify(p, ":h")
      project_dirs.direct[modified] = nil_insert(project_dirs.direct[modified], s)
    end
  end

  project_dirs.indirect = {}
  for dirname, statuses in pairs(project_dirs.direct) do
    for s, _ in pairs(statuses) do
      local modified = dirname
      while modified ~= cwd and modified ~= "/" do
        modified = vim.fn.fnamemodify(modified, ":h")
        project_dirs.indirect[modified] = nil_insert(project_dirs.indirect[modified], s)
      end
    end
  end

  for _, d in pairs(project_dirs) do
    for dirname, statuses in pairs(d) do
      local new_statuses = {}
      for s, _ in pairs(statuses) do
        table.insert(new_statuses, s)
      end
      d[dirname] = new_statuses
    end
  end

  return project_dirs
end

---Git file status for an absolute path
---@param parent_ignored boolean
---@param project GitProject?
---@param path string
---@param path_fallback string? alternative file path when no other file status
---@return GitNodeStatus
function M.git_status_file(parent_ignored, project, path, path_fallback)
  ---@type GitNodeStatus
  local ns

  if parent_ignored then
    ns = {
      file = "!!"
    }
  elseif project and project.files then
    ns = {
      file = project.files[path] or project.files[path_fallback]
    }
  else
    ns = {}
  end

  return ns
end

---Git file and directory status for an absolute path
---@param parent_ignored boolean
---@param project GitProject?
---@param path string
---@param path_fallback string? alternative file path when no other file status
---@return GitNodeStatus?
function M.git_status_dir(parent_ignored, project, path, path_fallback)
  ---@type GitNodeStatus?
  local ns

  if parent_ignored then
    ns = {
      file = "!!"
    }
  elseif project then
    ns = {
      file = project.files and (project.files[path] or project.files[path_fallback]),
      dir  = project.dirs and {
        direct   = project.dirs.direct and project.dirs.direct[path],
        indirect = project.dirs.indirect and project.dirs.indirect[path],
      },
    }
  end

  return ns
end

function M.setup(opts)
  if opts.git.cygwin_support then
    M.use_cygpath = vim.fn.executable("cygpath") == 1
  end
end

return M
