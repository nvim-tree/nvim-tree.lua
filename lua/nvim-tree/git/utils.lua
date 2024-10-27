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

---@param t table|nil
---@param k string
---@return table
local function nil_insert(t, k)
  t = t or {}
  t[k] = true
  return t
end

---@param status table
---@param cwd string|nil
---@return table
function M.file_status_to_dir_status(status, cwd)
  local direct = {}
  for p, s in pairs(status) do
    if s ~= "!!" then
      local modified = vim.fn.fnamemodify(p, ":h")
      direct[modified] = nil_insert(direct[modified], s)
    end
  end

  local indirect = {}
  for dirname, statuses in pairs(direct) do
    for s, _ in pairs(statuses) do
      local modified = dirname
      while modified ~= cwd and modified ~= "/" do
        modified = vim.fn.fnamemodify(modified, ":h")
        indirect[modified] = nil_insert(indirect[modified], s)
      end
    end
  end

  local r = { indirect = indirect, direct = direct }
  for _, d in pairs(r) do
    for dirname, statuses in pairs(d) do
      local new_statuses = {}
      for s, _ in pairs(statuses) do
        table.insert(new_statuses, s)
      end
      d[dirname] = new_statuses
    end
  end
  return r
end

---Git file status for an absolute path with optional fallback
---@param parent_ignored boolean
---@param status table?
---@param path string
---@param path_fallback string?
---@return GitStatus
function M.git_status_file(parent_ignored, status, path, path_fallback)
  ---@type GitStatus
  local st = {}

  if parent_ignored then
    st.file = "!!"
  elseif status and status.files then
    st.file = status.files[path] or status.files[path_fallback]
  end

  return st
end

---Git file and directory status for an absolute path with optional file fallback
---@param parent_ignored boolean
---@param status table?
---@param path string
---@param path_file string? alternative file path when no other file status
---@return GitStatus?
function M.git_status_dir(parent_ignored, status, path, path_file)
  ---@type GitStatus?
  local st

  if parent_ignored then
    st = {}
    st.file = "!!"
  elseif status then
    st = {}
    st.file = status.files and (status.files[path] or status.files[path_file])
    if status.dirs then
      st.dir = {}
      st.dir.direct = status.dirs.direct and status.dirs.direct[path]
      st.dir.indirect = status.dirs.indirect and status.dirs.indirect[path]
    end
  end

  return st
end

function M.setup(opts)
  if opts.git.cygwin_support then
    M.use_cygpath = vim.fn.executable("cygpath") == 1
  end
end

return M
