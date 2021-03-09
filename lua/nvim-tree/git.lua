local utils = require'nvim-tree.utils'
local M = {}

local roots = {}

local not_git = 'not a git repo'
local is_win = vim.api.nvim_call_function("has", {"win32"}) == 1

local function update_root_status(root)
  local untracked = ' -u'
  if vim.fn.trim(vim.fn.system('git config --type=bool status.showUntrackedFiles')) == 'false' then
    untracked = ''
  end
  local status = vim.fn.systemlist('cd "'..root..'" && git status --porcelain=v1'..untracked)
  roots[root] = {}

  for _, v in pairs(status) do
    local head = v:sub(0, 2)
    local body = v:sub(4, -1)
    if body:match('%->') ~= nil then
      body = body:gsub('^.* %-> ', '')
    end

    --- Git returns paths with a forward slash wherever you run it, thats why i have to replace it only on windows
    if is_win then
      body = body:gsub("/", "\\")
    end

    roots[root][body] = head
  end
end

function M.reload_roots()
  for root, status in pairs(roots) do
    if status ~= not_git then
      update_root_status(root)
    end
  end
end

local function get_git_root(path)
  if roots[path] then
    return path, roots[path]
  end

  for name, status in pairs(roots) do
    if status ~= not_git then
      if path:match(utils.path_to_matching_str(name)) then
        return name, status
      end
    end
  end
end

local function create_root(cwd)
  local git_root = vim.fn.system('cd "'..cwd..'" && git rev-parse --show-toplevel')

  if not git_root or #git_root == 0 or git_root:match('fatal') then
    roots[cwd] = not_git
    return false
  end

  if is_win then
    git_root = git_root:gsub("/", "\\")
  end

  update_root_status(git_root:sub(0, -2))
  return true
end

function M.update_status(entries, cwd)
  local git_root, git_status = get_git_root(cwd)
  if not git_root then
    if not create_root(cwd) then
      return
    end
    git_root, git_status = get_git_root(cwd)
  elseif git_status == not_git then
    return
  end

  if not git_root then
    return
  end

  local matching_cwd = utils.path_to_matching_str( utils.path_add_trailing(git_root) )

  for _, node in pairs(entries) do
    local relpath = node.absolute_path:gsub(matching_cwd, '')
    if node.entries ~= nil then
      relpath = utils.path_add_trailing(relpath)
      node.git_status = nil
    end

    local status = git_status[relpath]
    if status then
      node.git_status = status
    elseif node.entries ~= nil then
      local matcher = '^'..utils.path_to_matching_str(relpath)
      for key, entry_status in pairs(git_status) do
        if key:match(matcher) then
          node.git_status = entry_status
          break
        end
      end
    else
      node.git_status = nil
    end
  end
end

return M
