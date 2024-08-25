local lib = require "nvim-tree.lib"
local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local events = require "nvim-tree.events"
local notify = require "nvim-tree.notify"
local renderer = require "nvim-tree.renderer"
local reloaders = require "nvim-tree.actions.reloaders"

local find_file = require("nvim-tree.actions.finders.find-file").fn

---@enum ACTION
local ACTION = {
  copy = "copy",
  cut = "cut",
}

---@class Clipboard to handle all actions.fs clipboard API
---@field config table hydrated user opts.filters
---@field private explorer Explorer
---@field private data table<ACTION, Node[]>
local Clipboard = {}

---@param opts table user options
---@param explorer Explorer
---@return Clipboard
function Clipboard:new(opts, explorer)
  local o = {
    explorer = explorer,
    data = {
      [ACTION.copy] = {},
      [ACTION.cut] = {},
    },
    config = {
      filesystem_watchers = opts.filesystem_watchers,
      actions = opts.actions,
    },
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

---@param source string
---@param destination string
---@return boolean
---@return string|nil
local function do_copy(source, destination)
  local source_stats, handle
  local success, errmsg

  source_stats, errmsg = vim.loop.fs_stat(source)
  if not source_stats then
    log.line("copy_paste", "do_copy fs_stat '%s' failed '%s'", source, errmsg)
    return false, errmsg
  end

  log.line("copy_paste", "do_copy %s '%s' -> '%s'", source_stats.type, source, destination)

  if source == destination then
    log.line("copy_paste", "do_copy source and destination are the same, exiting early")
    return true
  end

  if source_stats.type == "file" then
    success, errmsg = vim.loop.fs_copyfile(source, destination)
    if not success then
      log.line("copy_paste", "do_copy fs_copyfile failed '%s'", errmsg)
      return false, errmsg
    end
    return true
  elseif source_stats.type == "directory" then
    handle, errmsg = vim.loop.fs_scandir(source)
    if type(handle) == "string" then
      return false, handle
    elseif not handle then
      log.line("copy_paste", "do_copy fs_scandir '%s' failed '%s'", source, errmsg)
      return false, errmsg
    end

    success, errmsg = vim.loop.fs_mkdir(destination, source_stats.mode)
    if not success then
      log.line("copy_paste", "do_copy fs_mkdir '%s' failed '%s'", destination, errmsg)
      return false, errmsg
    end

    while true do
      local name, _ = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      local new_name = utils.path_join { source, name }
      local new_destination = utils.path_join { destination, name }
      success, errmsg = do_copy(new_name, new_destination)
      if not success then
        return false, errmsg
      end
    end
  else
    errmsg = string.format("'%s' illegal file type '%s'", source, source_stats.type)
    log.line("copy_paste", "do_copy %s", errmsg)
    return false, errmsg
  end

  return true
end

---@param source string
---@param dest string
---@param action ACTION
---@param action_fn fun(source: string, dest: string)
---@return boolean|nil -- success
---@return string|nil -- error message
local function do_single_paste(source, dest, action, action_fn)
  local dest_stats
  local success, errmsg, errcode
  local notify_source = notify.render_path(source)

  log.line("copy_paste", "do_single_paste '%s' -> '%s'", source, dest)

  dest_stats, errmsg, errcode = vim.loop.fs_stat(dest)
  if not dest_stats and errcode ~= "ENOENT" then
    notify.error("Could not " .. action .. " " .. notify_source .. " - " .. (errmsg or "???"))
    return false, errmsg
  end

  local function on_process()
    success, errmsg = action_fn(source, dest)
    if not success then
      notify.error("Could not " .. action .. " " .. notify_source .. " - " .. (errmsg or "???"))
      return false, errmsg
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
---@param clip table
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
  self.data[ACTION.copy] = {}
  self.data[ACTION.cut] = {}
  notify.info "Clipboard has been emptied."
  renderer.draw()
end

---Copy one node
---@param node Node
function Clipboard:copy(node)
  utils.array_remove(self.data[ACTION.cut], node)
  toggle(node, self.data[ACTION.copy])
  renderer.draw()
end

---Cut one node
---@param node Node
function Clipboard:cut(node)
  utils.array_remove(self.data[ACTION.copy], node)
  toggle(node, self.data[ACTION.cut])
  renderer.draw()
end

---Paste cut or cop
---@private
---@param node Node
---@param action ACTION
---@param action_fn fun(source: string, dest: string)
function Clipboard:do_paste(node, action, action_fn)
  node = lib.get_last_group_node(node)
  local explorer = core.get_explorer()
  if node.name == ".." and explorer then
    node = explorer
  end
  local clip = self.data[action]
  if #clip == 0 then
    return
  end

  local destination = node.absolute_path
  local stats, errmsg, errcode = vim.loop.fs_stat(destination)
  if not stats and errcode ~= "ENOENT" then
    log.line("copy_paste", "do_paste fs_stat '%s' failed '%s'", destination, errmsg)
    notify.error("Could not " .. action .. " " .. notify.render_path(destination) .. " - " .. (errmsg or "???"))
    return
  end
  local is_dir = stats and stats.type == "directory"
  if not is_dir then
    destination = vim.fn.fnamemodify(destination, ":p:h")
  end

  for _, _node in ipairs(clip) do
    local dest = utils.path_join { destination, _node.name }
    do_single_paste(_node.absolute_path, dest, action, action_fn)
  end

  self.data[action] = {}
  if not self.config.filesystem_watchers.enable then
    reloaders.reload_explorer()
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
  if self.data[ACTION.cut][1] ~= nil then
    self:do_paste(node, ACTION.cut, do_cut)
  elseif self.data[ACTION.copy][1] ~= nil then
    self:do_paste(node, ACTION.copy, do_copy)
  end
end

function Clipboard:print_clipboard()
  local content = {}
  if #self.data[ACTION.cut] > 0 then
    table.insert(content, "Cut")
    for _, node in pairs(self.data[ACTION.cut]) do
      table.insert(content, " * " .. (notify.render_path(node.absolute_path)))
    end
  end
  if #self.data[ACTION.copy] > 0 then
    table.insert(content, "Copy")
    for _, node in pairs(self.data[ACTION.copy]) do
      table.insert(content, " * " .. (notify.render_path(node.absolute_path)))
    end
  end

  notify.info(table.concat(content, "\n") .. "\n")
end

---@param content string
function Clipboard:copy_to_reg(content)
  local clipboard_name
  local reg
  if self.config.actions.use_system_clipboard == true then
    clipboard_name = "system"
    reg = "+"
  else
    clipboard_name = "neovim"
    reg = "1"
  end

  -- manually firing TextYankPost does not set vim.v.event
  -- workaround: create a scratch buffer with the clipboard contents and send a yank command
  local temp_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_text(temp_buf, 0, 0, 0, 0, { content })
  vim.api.nvim_buf_call(temp_buf, function()
    vim.cmd(string.format('normal! "%sy$', reg))
  end)
  vim.api.nvim_buf_delete(temp_buf, {})

  notify.info(string.format("Copied %s to %s clipboard!", content, clipboard_name))
end

---@param node Node
function Clipboard:copy_filename(node)
  self:copy_to_reg(node.name)
end

---@param node Node
function Clipboard:copy_basename(node)
  local basename = vim.fn.fnamemodify(node.name, ":r")
  self:copy_to_reg(basename)
end

---@param node Node
function Clipboard:copy_path(node)
  local absolute_path = node.absolute_path
  local cwd = core.get_cwd()
  if cwd == nil then
    return
  end

  local relative_path = utils.path_relative(absolute_path, cwd)
  local content = node.nodes ~= nil and utils.path_add_trailing(relative_path) or relative_path
  self:copy_to_reg(content)
end

---@param node Node
function Clipboard:copy_absolute_path(node)
  local absolute_path = node.absolute_path
  local content = node.nodes ~= nil and utils.path_add_trailing(absolute_path) or absolute_path
  self:copy_to_reg(content)
end

---Node is cut. Will not be copied.
---@param node Node
---@return boolean
function Clipboard:is_cut(node)
  return vim.tbl_contains(self.data[ACTION.cut], node)
end

---Node is copied. Will not be cut.
---@param node Node
---@return boolean
function Clipboard:is_copied(node)
  return vim.tbl_contains(self.data[ACTION.copy], node)
end

return Clipboard
