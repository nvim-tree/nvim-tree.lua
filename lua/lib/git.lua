local api = vim.api
local config = require 'lib/config'
local utils = require'lib.utils'

local M = {}

local function system(v) return api.nvim_call_function('system', { v }) end
local function systemlist(v) return api.nvim_call_function('systemlist', { v }) end

local function is_git_repo()
  local is_git = system('git rev-parse')
  return is_git:match('fatal') == nil
end

local IS_GIT_REPO = is_git_repo()

local function set_git_status()
  if IS_GIT_REPO == false then return '' end
  return systemlist('git status --porcelain=v1')
end

local GIT_STATUS = set_git_status()

function M.refresh_git()
  if IS_GIT_REPO == false then return false end
  GIT_STATUS = set_git_status()
  return true
end

function M.force_refresh_git()
  IS_GIT_REPO = is_git_repo()
  M.refresh_git()
end

local function is_folder_dirty(relpath)
  for _, status in pairs(GIT_STATUS) do
    if status:match(utils.path_to_matching_str(relpath)) ~= nil then
      return true
    end
  end
end

local function create_git_checker(pattern)
  return function(relpath)
    for _, status in pairs(GIT_STATUS) do
      local ret = status:match('^.. .*' .. utils.path_to_matching_str(relpath))
      if ret ~= nil and ret:match(pattern) ~= nil then return true end
    end
    return false
  end
end

local unstaged = create_git_checker('^ ')
local staged = create_git_checker('^M ')
local staged_new = create_git_checker('^A ')
local staged_mod = create_git_checker('^MM')
local unmerged = create_git_checker('^[U ][U ]')
local renamed = create_git_checker('^R')
local untracked = create_git_checker('^%?%?')

function M.get_git_attr(path, is_dir)
  if IS_GIT_REPO == false or not config.SHOW_GIT_ICON then return '' end
  if is_dir then
    if is_folder_dirty(path) == true then return '✗ ' end
  else
    if unstaged(path) then return '✗ '
    elseif staged(path) then return '✓ '
    elseif staged_new(path) then return '✓★ '
    elseif staged_mod(path) then return '✓✗ '
    elseif unmerged(path) then return '═ '
    elseif renamed(path) then return '➜ '
    elseif untracked(path) then return '★ '
    end
  end

  return ''
end

return M
