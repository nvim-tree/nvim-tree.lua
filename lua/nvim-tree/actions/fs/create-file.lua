local utils = require("nvim-tree.utils")
local events = require("nvim-tree.events")
local core = require("nvim-tree.core")
local notify = require("nvim-tree.notify")

local find_file = require("nvim-tree.actions.finders.find-file").fn

local FileNode = require("nvim-tree.node.file")
local DirectoryNode = require("nvim-tree.node.directory")

local M = {}

---@param file string
local function create_and_notify(file)
  events._dispatch_will_create_file(file)
  local ok, fd = pcall(vim.loop.fs_open, file, "w", 420)
  if not ok or type(fd) ~= "number" then
    notify.error("Couldn't create file " .. notify.render_path(file))
    return
  end
  vim.loop.fs_close(fd)
  events._dispatch_file_created(file)
end

---@param iter function iterable
---@return integer
local function get_num_nodes(iter)
  local i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

---@param node Node?
function M.fn(node)
  node = node or core.get_explorer()
  if not node then
    return
  end

  local dir = node:is(FileNode) and node.parent or node:as(DirectoryNode)
  if not dir then
    return
  end

  dir = dir:last_group_node()

  local containing_folder = utils.path_add_trailing(dir.absolute_path)

  local input_opts = {
    prompt = "Create file ",
    default = containing_folder,
    completion = "file",
  }

  vim.ui.input(input_opts, function(new_file_path)
    utils.clear_prompt()
    if not new_file_path or new_file_path == containing_folder then
      return
    end

    if utils.file_exists(new_file_path) then
      notify.warn("Cannot create: file already exists")
      return
    end

    -- create a folder for each path element if the folder does not exist
    -- if the answer ends with a /, create a file for the last path element
    local is_last_path_file = not new_file_path:match(utils.path_separator .. "$")
    local path_to_create = ""
    local idx = 0

    local num_nodes = get_num_nodes(utils.path_split(utils.path_remove_trailing(new_file_path)))
    local is_error = false
    for path in utils.path_split(new_file_path) do
      idx = idx + 1
      local p = utils.path_remove_trailing(path)
      if #path_to_create == 0 and vim.fn.has("win32") == 1 then
        path_to_create = utils.path_join({ p, path_to_create })
      else
        path_to_create = utils.path_join({ path_to_create, p })
      end
      if is_last_path_file and idx == num_nodes then
        create_and_notify(path_to_create)
      elseif not utils.file_exists(path_to_create) then
        local success = vim.loop.fs_mkdir(path_to_create, 493)
        if not success then
          notify.error("Could not create folder " .. notify.render_path(path_to_create))
          is_error = true
          break
        end
        events._dispatch_folder_created(new_file_path)
      end
    end
    if not is_error then
      notify.info(notify.render_path(new_file_path) .. " was properly created")
    end

    -- synchronously refreshes as we can't wait for the watchers
    find_file(utils.path_remove_trailing(new_file_path))
  end)
end

return M
