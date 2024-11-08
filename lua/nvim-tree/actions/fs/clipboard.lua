local lib = require("nvim-tree.lib")
local log = require("nvim-tree.log")
local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")
local events = require("nvim-tree.events")
local notify = require("nvim-tree.notify")

local find_file = require("nvim-tree.actions.finders.find-file").fn

local Class = require("nvim-tree.classic")
local DirectoryNode = require("nvim-tree.node.directory")

---@alias ClipboardAction "copy" | "cut"
---@alias ClipboardData table<ClipboardAction, Node[]>

---@alias ClipboardActionFn fun(source: string, dest: string): boolean, string?

---@class (exact) Clipboard: Class
---@field private explorer Explorer
---@field private data ClipboardData
---@field private clipboard_name string
---@field private reg string
local Clipboard = Class:extend()

---@class Clipboard
---@overload fun(args: ClipboardArgs): Clipboard

---@class (exact) ClipboardArgs
---@field explorer Explorer

---@protected
---@param args ClipboardArgs
function Clipboard:new(args)
  self.explorer = args.explorer

  self.data = {
    copy = {},
    cut = {},
  }

  self.clipboard_name = self.explorer.opts.actions.use_system_clipboard and "system" or "neovim"
  self.reg = self.explorer.opts.actions.use_system_clipboard and "+" or "1"
end

---@param source string
---@param destination string
---@return boolean
---@return string|nil
local function do_copy(source, destination)
  local source_stats, err = vim.loop.fs_stat(source)

  if not source_stats then
    log.line("copy_paste", "do_copy fs_stat '%s' failed '%s'", source, err)
    return false, err
  end

  log.line("copy_paste", "do_copy %s '%s' -> '%s'", source_stats.type, source, destination)

  if source == destination then
    log.line("copy_paste", "do_copy source and destination are the same, exiting early")
    return true
  end

  if source_stats.type == "file" then
    local success
    success, err = vim.loop.fs_copyfile(source, destination)
    if not success then
      log.line("copy_paste", "do_copy fs_copyfile failed '%s'", err)
      return false, err
    end
    return true
  elseif source_stats.type == "directory" then
    local handle
    handle, err = vim.loop.fs_scandir(source)
    if type(handle) == "string" then
      return false, handle
    elseif not handle then
      log.line("copy_paste", "do_copy fs_scandir '%s' failed '%s'", source, err)
      return false, err
    end

    local success
    success, err = vim.loop.fs_mkdir(destination, source_stats.mode)
    if not success then
      log.line("copy_paste", "do_copy fs_mkdir '%s' failed '%s'", destination, err)
      return false, err
    end

    while true do
      local name, _ = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      local new_name = utils.path_join({ source, name })
      local new_destination = utils.path_join({ destination, name })
      success, err = do_copy(new_name, new_destination)
      if not success then
        return false, err
      end
    end
  else
    err = string.format("'%s' illegal file type '%s'", source, source_stats.type)
    log.line("copy_paste", "do_copy %s", err)
    return false, err
  end

  return true
end

---@param source string
---@param dest string
---@param action ClipboardAction
---@param action_fn ClipboardActionFn
---@return boolean|nil -- success
---@return string|nil -- error message
local function do_single_paste(source, dest, action, action_fn)
  local notify_source = notify.render_path(source)

  log.line("copy_paste", "do_single_paste '%s' -> '%s'", source, dest)

  local dest_stats, err, err_name = vim.loop.fs_stat(dest)
  if not dest_stats and err_name ~= "ENOENT" then
    notify.error("Could not " .. action .. " " .. notify_source .. " - " .. (err or "???"))
    return false, err
  end

  local function on_process()
    local success, error = action_fn(source, dest)
    if not success then
      notify.error("Could not " .. action .. " " .. notify_source .. " - " .. (error or "???"))
      return false, error
    end

    find_file(utils.path_remove_trailing(dest))
  end

  if dest_stats then
    local input_opts = {
      prompt = "Rename to ",
      default = dest,
      completion = "dir",
    }

    if source == dest then
      vim.ui.input(input_opts, function(new_dest)
        utils.clear_prompt()
        if new_dest then
          do_single_paste(source, new_dest, action, action_fn)
        end
      end)
    else
      local prompt_select = "Overwrite " .. dest .. " ?"
      local prompt_input = prompt_select .. " R(ename)/y/n: "
      lib.prompt(prompt_input, prompt_select, { "", "y", "n" }, { "Rename", "Yes", "No" }, "nvimtree_overwrite_rename", function(item_short)
        utils.clear_prompt()
        if item_short == "y" then
          on_process()
        elseif item_short == "" or item_short == "r" then
          vim.ui.input(input_opts, function(new_dest)
            utils.clear_prompt()
            if new_dest then
              do_single_paste(source, new_dest, action, action_fn)
            end
          end)
        end
      end)
    end
  else
    on_process()
  end
end

---@param node Node
---@param clip ClipboardData
local function toggle(node, clip)
  if node.name == ".." then
    return
  end
  local notify_node = notify.render_path(node.absolute_path)

  if utils.array_remove(clip, node) then
    notify.info(notify_node .. " removed from clipboard.")
    return
  end

  table.insert(clip, node)
  notify.info(notify_node .. " added to clipboard.")
end

---Clear copied and cut
function Clipboard:clear_clipboard()
  self.data.copy = {}
  self.data.cut = {}
  notify.info("Clipboard has been emptied.")
  self.explorer.renderer:draw()
end

---Copy one node
---@param node Node
function Clipboard:copy(node)
  utils.array_remove(self.data.cut, node)
  toggle(node, self.data.copy)
  self.explorer.renderer:draw()
end

---Cut one node
---@param node Node
function Clipboard:cut(node)
  utils.array_remove(self.data.copy, node)
  toggle(node, self.data.cut)
  self.explorer.renderer:draw()
end

---Paste cut or cop
---@private
---@param node Node
---@param action ClipboardAction
---@param action_fn ClipboardActionFn
function Clipboard:do_paste(node, action, action_fn)
  if node.name == ".." then
    node = self.explorer
  else
    local dir = node:as(DirectoryNode)
    if dir then
      node = dir:last_group_node()
    end
  end
  local clip = self.data[action]
  if #clip == 0 then
    return
  end

  local destination = node.absolute_path
  local stats, err, err_name = vim.loop.fs_stat(destination)
  if not stats and err_name ~= "ENOENT" then
    log.line("copy_paste", "do_paste fs_stat '%s' failed '%s'", destination, err)
    notify.error("Could not " .. action .. " " .. notify.render_path(destination) .. " - " .. (err or "???"))
    return
  end
  local is_dir = stats and stats.type == "directory"
  if not is_dir then
    destination = vim.fn.fnamemodify(destination, ":p:h")
  end

  for _, _node in ipairs(clip) do
    local dest = utils.path_join({ destination, _node.name })
    do_single_paste(_node.absolute_path, dest, action, action_fn)
  end

  self.data[action] = {}
  if not self.explorer.opts.filesystem_watchers.enable then
    self.explorer:reload_explorer()
  end
end

---@param source string
---@param destination string
---@return boolean
---@return string?
local function do_cut(source, destination)
  log.line("copy_paste", "do_cut '%s' -> '%s'", source, destination)

  if source == destination then
    log.line("copy_paste", "do_cut source and destination are the same, exiting early")
    return true
  end

  events._dispatch_will_rename_node(source, destination)
  local success, errmsg = vim.loop.fs_rename(source, destination)
  if not success then
    log.line("copy_paste", "do_cut fs_rename failed '%s'", errmsg)
    return false, errmsg
  end
  utils.rename_loaded_buffers(source, destination)
  events._dispatch_node_renamed(source, destination)
  return true
end

---Paste cut (if present) or copy (if present)
---@param node Node
function Clipboard:paste(node)
  if self.data.cut[1] ~= nil then
    self:do_paste(node, "cut", do_cut)
  elseif self.data.copy[1] ~= nil then
    self:do_paste(node, "copy", do_copy)
  end
end

function Clipboard:print_clipboard()
  local content = {}
  if #self.data.cut > 0 then
    table.insert(content, "Cut")
    for _, node in pairs(self.data.cut) do
      table.insert(content, " * " .. (notify.render_path(node.absolute_path)))
    end
  end
  if #self.data.copy > 0 then
    table.insert(content, "Copy")
    for _, node in pairs(self.data.copy) do
      table.insert(content, " * " .. (notify.render_path(node.absolute_path)))
    end
  end

  notify.info(table.concat(content, "\n") .. "\n")
end

---@param content string
function Clipboard:copy_to_reg(content)
  -- manually firing TextYankPost does not set vim.v.event
  -- workaround: create a scratch buffer with the clipboard contents and send a yank command
  local temp_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_text(temp_buf, 0, 0, 0, 0, { content })
  vim.api.nvim_buf_call(temp_buf, function()
    vim.cmd(string.format('normal! "%sy$', self.reg))
  end)
  vim.api.nvim_buf_delete(temp_buf, {})

  notify.info(string.format("Copied %s to %s clipboard!", content, self.clipboard_name))
end

---@param node Node
function Clipboard:copy_filename(node)
  if node.name == ".." then
    -- root
    self:copy_to_reg(vim.fn.fnamemodify(self.explorer.absolute_path, ":t"))
  else
    -- node
    self:copy_to_reg(node.name)
  end
end

---@param node Node
function Clipboard:copy_basename(node)
  if node.name == ".." then
    -- root
    self:copy_to_reg(vim.fn.fnamemodify(self.explorer.absolute_path, ":t:r"))
  else
    -- node
    self:copy_to_reg(vim.fn.fnamemodify(node.name, ":r"))
  end
end

---@param node Node
function Clipboard:copy_path(node)
  if node.name == ".." then
    -- root
    self:copy_to_reg(utils.path_add_trailing(""))
  else
    -- node
    local absolute_path = node.absolute_path
    local cwd = core.get_cwd()
    if cwd == nil then
      return
    end

    local relative_path = utils.path_relative(absolute_path, cwd)
    if node:is(DirectoryNode) then
      self:copy_to_reg(utils.path_add_trailing(relative_path))
    else
      self:copy_to_reg(relative_path)
    end
  end
end

---@param node Node
function Clipboard:copy_absolute_path(node)
  if node.name == ".." then
    node = self.explorer
  end

  local absolute_path = node.absolute_path
  local content = node.nodes ~= nil and utils.path_add_trailing(absolute_path) or absolute_path
  self:copy_to_reg(content)
end

---Node is cut. Will not be copied.
---@param node Node
---@return boolean
function Clipboard:is_cut(node)
  return vim.tbl_contains(self.data.cut, node)
end

---Node is copied. Will not be cut.
---@param node Node
---@return boolean
function Clipboard:is_copied(node)
  return vim.tbl_contains(self.data.copy, node)
end

return Clipboard
