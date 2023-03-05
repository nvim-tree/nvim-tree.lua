local M = {}
local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"

function M.get_toplevel(cwd)
  local profile = log.profile_start("git toplevel %s", cwd)

  local cmd = { "git", "-C", cwd, "rev-parse", "--show-toplevel" }
  log.line("git", "%s", vim.inspect(cmd))

  local toplevel = vim.fn.system(cmd)

  log.raw("git", toplevel)
  log.profile_end(profile)

  if vim.v.shell_error ~= 0 or not toplevel or #toplevel == 0 or toplevel:match "fatal" then
    return nil
  end

  toplevel = utils.norm_path(toplevel)
  if toplevel == nil then
    return nil
  end

  -- remove newline
  return toplevel:sub(0, -2)
end

local untracked = {}

function M.should_show_untracked(cwd)
  if untracked[cwd] ~= nil then
    return untracked[cwd]
  end

  local profile = log.profile_start("git untracked %s", cwd)

  local cmd = { "git", "-C", cwd, "config", "status.showUntrackedFiles" }
  log.line("git", vim.inspect(cmd))

  local has_untracked = vim.fn.system(cmd)

  log.raw("git", has_untracked)
  log.profile_end(profile)

  untracked[cwd] = vim.trim(has_untracked) ~= "no"
  return untracked[cwd]
end

local function nil_insert(t, k)
  t = t or {}
  t[k] = true
  return t
end

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

function M.get_git_directory(cwd)
  local profile = log.profile_start("git directory %s", cwd)

  local cmd = { "git", "-C", cwd, "rev-parse", "--absolute-git-dir" }
  log.line("git", vim.inspect(cmd))

  local git_dir = vim.fn.system(cmd)

  log.raw("git", git_dir)
  log.profile_end(profile)

  if vim.v.shell_error ~= 0 or not git_dir or #git_dir == 0 or git_dir:match "fatal" then
    return nil
  end

  git_dir = utils.norm_path(git_dir)
  if git_dir == nil then
    return nil
  end

  -- remove newline
  return git_dir:sub(0, -2)
end

return M
