local utils = require'nvim-tree.utils'
local M = {}

local roots = {}

---A map from git roots to a list of ignored paths
local gitignore_map = {}

local not_git = 'not a git repo'
local is_win = vim.api.nvim_call_function("has", {"win32"}) == 1

local function update_root_status(root)
  local e_root = vim.fn.shellescape(root)
  local untracked = ' -u'

  local cmd = "git -C " .. e_root .. " config --type=bool status.showUntrackedFiles"
  if vim.trim(vim.fn.system(cmd)) == 'false' then
    untracked = ''
  end

  cmd = "git -C " .. e_root .. " status --porcelain=v1 --ignored=matching" .. untracked
  local status = vim.fn.systemlist(cmd)

  roots[root] = {}
  gitignore_map[root] = {}

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

    if head == "!!" then
      gitignore_map[root][utils.path_remove_trailing(utils.path_join({root, body}))] = true
    end
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
  local cmd = "git -C " .. vim.fn.shellescape(cwd) .. " rev-parse --show-toplevel"
  local git_root = vim.fn.system(cmd)

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

---Get the root of the git dir containing the given path or `nil` if it's not a
---git dir.
---@param path string
---@return string|nil
function M.git_root(path)
  local git_root, git_status = get_git_root(path)
  if not git_root then
    if not create_root(path) then
      return
    end
    git_root, git_status = get_git_root(path)
  end

  if git_status == not_git then
    return
  end

  return git_root
end

function M.update_status(entries, cwd, parent_node)
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

  if not parent_node then parent_node = {} end

  local matching_cwd = utils.path_to_matching_str( utils.path_add_trailing(git_root) )

  for _, node in pairs(entries) do
    if parent_node.git_status == "!!" then
      node.git_status = "!!"
    else
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
          if entry_status ~= "!!" and key:match(matcher) then
            node.git_status = entry_status
            break
          end
        end
      else
        node.git_status = nil
      end
    end
  end
end

---Check if the given path is ignored by git.
---@param path string Absolute path
---@return boolean
function M.should_gitignore(path)
  for _, paths in pairs(gitignore_map) do
    if paths[path] == true then
      return true
    end
  end
  return false
end

return M
