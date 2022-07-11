local a = vim.api
local uv = vim.loop

local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local lib = require "nvim-tree.lib"
local core = require "nvim-tree.core"

local M = {}

local function create_file(file)
  if utils.file_exists(file) then
    print(file .. " already exists. Overwrite? y/n")
    local ans = utils.get_user_input_char()
    utils.clear_prompt()
    if ans ~= "y" then
      return
    end
  end
  local ok, fd = pcall(uv.fs_open, file, "w", 420)
  if not ok then
    a.nvim_err_writeln("Couldn't create file " .. file)
    return
  end
  uv.fs_close(fd)
  events._dispatch_file_created(file)
end

local function get_num_nodes(iter)
  local i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

local function get_containing_folder(node)
  local is_open = M.create_in_closed_folder or node.open
  if node.nodes ~= nil and is_open then
    return utils.path_add_trailing(node.absolute_path)
  end
  local node_name_size = #(node.name or "")
  return node.absolute_path:sub(0, -node_name_size - 1)
end

function M.fn(node)
  node = lib.get_last_group_node(node)
  if node.name == ".." then
    node = {
      absolute_path = core.get_cwd(),
      nodes = core.get_explorer().nodes,
      open = true,
    }
  end

  local containing_folder = get_containing_folder(node)

  local input_opts = { prompt = "Create file ", default = containing_folder, completion = "file" }

  vim.ui.input(input_opts, function(new_file_path)
    if not new_file_path or new_file_path == containing_folder then
      return
    end

    utils.clear_prompt()

    if utils.file_exists(new_file_path) then
      utils.warn "Cannot create: file already exists"
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
      if #path_to_create == 0 and vim.fn.has "win32" == 1 then
        path_to_create = utils.path_join { p, path_to_create }
      else
        path_to_create = utils.path_join { path_to_create, p }
      end
      if is_last_path_file and idx == num_nodes then
        create_file(path_to_create)
      elseif not utils.file_exists(path_to_create) then
        local success = uv.fs_mkdir(path_to_create, 493)
        if not success then
          a.nvim_err_writeln("Could not create folder " .. path_to_create)
          is_error = true
          break
        end
      end
    end
    if not is_error then
      a.nvim_out_write(new_file_path .. " was properly created\n")
    end
    events._dispatch_folder_created(new_file_path)
    if M.enable_reload then
      require("nvim-tree.actions.reloaders.reloaders").reload_explorer()
    end
    -- INFO: defer needed when reload is automatic (watchers)
    vim.defer_fn(function()
      utils.focus_file(new_file_path)
    end, 150)
  end)
end

function M.setup(opts)
  M.create_in_closed_folder = opts.create_in_closed_folder
  M.enable_reload = not opts.filesystem_watchers.enable
end

return M
