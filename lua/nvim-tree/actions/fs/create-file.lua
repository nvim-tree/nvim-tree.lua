local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"
local lib = require "nvim-tree.lib"
local core = require "nvim-tree.core"
local notify = require "nvim-tree.notify"

local find_file = require("nvim-tree.actions.finders.find-file").fn
local async = require "nvim-tree.async"

local M = {}

---@async
local function create_and_notify(file)
  local fd, err
  if M.enable_async then
    err, fd = async.call(vim.loop.fs_open, file, "w", 420)
  else
    fd, err = vim.loop.fs_open(file, "w", 420)
  end
  if err then
    notify.error("Couldn't create file " .. file)
    return
  end
  if M.enable_async then
    async.call(vim.loop.fs_close, fd)
  else
    vim.loop.fs_close(fd)
  end
  events._dispatch_file_created(file)
end

local function get_num_nodes(iter)
  local i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

local function create_file(new_file_path)
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
    if #path_to_create == 0 and utils.is_windows then
      path_to_create = utils.path_join { p, path_to_create }
    else
      path_to_create = utils.path_join { path_to_create, p }
    end
    if is_last_path_file and idx == num_nodes then
      if M.enable_async then
        async.schedule()
      end
      if utils.file_exists(new_file_path) then
        local prompt_select = "Overwrite " .. new_file_path .. " ?"
        local prompt_input = prompt_select .. " y/n: "
        if M.enable_async then
          local item_short = async.call(lib.prompt, prompt_input, prompt_select, { "y", "n" }, { "Yes", "No" })
          utils.clear_prompt()
          if item_short == "y" then
            create_and_notify(new_file_path)
          end
        else
          lib.prompt(prompt_input, prompt_select, { "y", "n" }, { "Yes", "No" }, function(item_short)
            utils.clear_prompt()
            if item_short == "y" then
              create_and_notify(new_file_path)
            end
          end)
        end
      else
        create_and_notify(new_file_path)
      end
    elseif not utils.file_exists(path_to_create) then
      local err
      if M.enable_async then
        err = async.call(vim.loop.fs_mkdir, path_to_create, 493)
      else
        local _
        _, err = vim.loop.fs_mkdir(path_to_create, 493)
      end
      if err then
        notify.error("Could not create folder " .. path_to_create .. ": " .. err)
        is_error = true
        break
      end
      events._dispatch_folder_created(new_file_path)
    end
  end
  if not is_error then
    notify.info(new_file_path .. " was properly created")
  end
end

local function get_containing_folder(node)
  if node.nodes ~= nil then
    return utils.path_add_trailing(node.absolute_path)
  end
  local node_name_size = #(node.name or "")
  return node.absolute_path:sub(0, -node_name_size - 1)
end

--TODO: once async feature is finalized, use `async.wrap` instead of cb param
function M.fn(node, cb)
  node = node and lib.get_last_group_node(node)
  if not node or node.name == ".." then
    node = {
      absolute_path = core.get_cwd(),
      nodes = core.get_explorer().nodes,
      open = true,
    }
  end

  local containing_folder = get_containing_folder(node)

  local input_opts = { prompt = "Create file ", default = containing_folder, completion = "file" }

  vim.ui.input(input_opts, function(new_file_path)
    utils.clear_prompt()
    if not new_file_path or new_file_path == containing_folder then
      return
    end

    if utils.file_exists(new_file_path) then
      notify.warn "Cannot create: file already exists"
      return
    end

    if M.enable_async then
      async.exec(create_file, new_file_path, function(err)
        find_file(utils.path_remove_trailing(new_file_path))
        if cb then
          cb(err)
        end
      end)
    else
      create_file(new_file_path)
      -- synchronously refreshes as we can't wait for the watchers
      find_file(utils.path_remove_trailing(new_file_path))
    end
  end)
end

function M.setup(opts)
  M.enable_reload = not opts.filesystem_watchers.enable
  M.enable_async = opts.experimental.async.create_file
end

return M
