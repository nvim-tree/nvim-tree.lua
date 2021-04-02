local luv = vim.loop
local utils = require'nvim-tree.utils'
local M = {}

local roots = {}
local fstat_cache = {}

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

function M.get_gitexclude()
  return vim.fn.system("git ls-files --others --ignored --exclude-standard --directory")
end

--- Returns a list of all ignored files and directories in the given git directory.
---@param git_root string
---@return table
function M.get_gitignored(git_root)
  local seen = {}
  local result = {}
  local exclude_dirs = vim.fn.systemlist("cd " .. git_root .. " && git ls-files --others --ignored --exclude-standard --directory")
  local exclude_files = vim.fn.systemlist("cd " .. git_root .. " && git ls-files --others --ignored --exclude-standard")

  for _, t in ipairs({exclude_dirs, exclude_files}) do
    for _, s in ipairs(t) do
      if not seen[s] then
        seen[s] = true
        table.insert(result, s)
      end
    end
  end

  return result
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
  local should_gitignore = M.gen_should_gitignore(cwd)
  local num_ignored = 0

  for _, node in pairs(entries) do
    if parent_node.git_status == "ignored" or should_gitignore(node.absolute_path) then
      node.git_status = "ignored"
      num_ignored = num_ignored + 1
      goto continue
    end

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
    ::continue::
  end

  if num_ignored > 0 and num_ignored == #entries then
    parent_node.git_status = "ignored"
  end
end

local gitignore_list = {}

--- Generates a function that checks if a given path is ignored by git.
---@param cwd string Absolute path to current directory
---@return function
function M.gen_should_gitignore(cwd)
  local should_gitignore = function(path)
    return gitignore_list[path] == true
  end

  local git_root, git_status = get_git_root(cwd)
  if not git_root then
    if not create_root(cwd) then
      return should_gitignore
    end
    git_root, git_status = get_git_root(cwd)
  elseif git_status == not_git then
    return should_gitignore
  end

  -- The mtime for `.gitignore` and `.git/info/exclude` is cached such that the
  -- list of ignored files is only recreated when one of the said files are
  -- modified.
  local recreate = false
  for _, s in ipairs({".gitignore", ".git/info/exclude"}) do
    local path = utils.path_join({git_root, s})
    local stat = luv.fs_stat(path)
    if stat and stat.mtime then
      if not (fstat_cache[path]
          and fstat_cache[path].mtime == stat.mtime.sec) then

        recreate = true
        fstat_cache[path] = {
          mtime = stat.mtime.sec
        }
      end
    end
  end

  -- if we get a cache hit on all ignore files, there's no need to recreate the
  -- ignore list.
  if not recreate then
    return should_gitignore
  end

  gitignore_list = {}
  for _, s in ipairs(M.get_gitignored(git_root)) do
    if s:sub(#s, #s) == "/" then
      s = s:sub(1, #s - 1)
    end
    gitignore_list[utils.path_join({cwd, s})] = true
  end

  return should_gitignore
end

return M
