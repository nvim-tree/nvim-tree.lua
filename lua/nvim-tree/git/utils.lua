local M = {}
local log = require "nvim-tree.log"

local has_cygpath = vim.fn.executable "cygpath" == 1

function M.get_toplevel(cwd)
  local ps = log.profile_start("git toplevel %s", cwd)

  local cmd = { "git", "-C", cwd, "rev-parse", "--show-toplevel" }
  log.line("git", "%s", vim.inspect(cmd))

  local toplevel = vim.fn.system(cmd)

  log.raw("git", toplevel)
  log.profile_end(ps, "git toplevel %s", cwd)

  if vim.v.shell_error ~= 0 or not toplevel or #toplevel == 0 or toplevel:match "fatal" then
    return nil
  end

  -- git always returns path with forward slashes
  if vim.fn.has "win32" == 1 then
    -- msys2 git support
    if has_cygpath then
      toplevel = vim.fn.system("cygpath -w " .. vim.fn.shellescape(toplevel))
      if vim.v.shell_error ~= 0 then
        return nil
      end
    end
    toplevel = toplevel:gsub("/", "\\")
  end

  -- remove newline
  return toplevel:sub(0, -2)
end

local untracked = {}

function M.should_show_untracked(cwd)
  if untracked[cwd] ~= nil then
    return untracked[cwd]
  end

  local ps = log.profile_start("git untracked %s", cwd)

  local cmd = { "git", "-C", cwd, "config", "status.showUntrackedFiles" }
  log.line("git", vim.inspect(cmd))

  local has_untracked = vim.fn.system(cmd)

  log.raw("git", has_untracked)
  log.profile_end(ps, "git untracked %s", cwd)

  untracked[cwd] = vim.trim(has_untracked) ~= "no"
  return untracked[cwd]
end

function M.file_status_to_dir_status(status, cwd)
  local dirs = {}
  for p, s in pairs(status) do
    if s ~= "!!" then
      local modified = vim.fn.fnamemodify(p, ":h")
      dirs[modified] = s
    end
  end

  for dirname, s in pairs(dirs) do
    local modified = dirname
    while modified ~= cwd and modified ~= "/" do
      modified = vim.fn.fnamemodify(modified, ":h")
      dirs[modified] = s
    end
  end

  return dirs
end

return M
