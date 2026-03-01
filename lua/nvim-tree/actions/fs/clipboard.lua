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

---@class (exact) Clipboard: nvim_tree.Class
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

---Paste a single item with no conflict handling.
---@param source string
---@param dest string
---@param action ClipboardAction
---@param action_fn ClipboardActionFn
local function do_paste_one(source, dest, action, action_fn)
  log.line("copy_paste", "do_paste_one '%s' -> '%s'", source, dest)
  local success, err = action_fn(source, dest)
  if not success then
    notify.error("Could not " .. action .. " " .. notify.render_path(source) .. " - " .. (err or "???"))
  end
  find_file(utils.path_remove_trailing(dest))
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

---Bulk add/remove nodes to/from a clipboard list.
---@private
---@param nodes Node[] filtered nodes to operate on
---@param from Node[] list to remove from (the opposite clipboard)
---@param to Node[] list to add to
---@param verb string notification verb ("added to" or "cut to")
function Clipboard:bulk_clipboard(nodes, from, to, verb)
  local added = 0
  local removed = 0
  for _, node in ipairs(nodes) do
    if node.name ~= ".." then
      utils.array_remove(from, node)
      if utils.array_remove(to, node) then
        removed = removed + 1
      else
        table.insert(to, node)
        added = added + 1
      end
    end
  end
  if added > 0 then
    notify.info(string.format("%d nodes %s clipboard.", added, verb))
  elseif removed > 0 then
    notify.info(string.format("%d nodes removed from clipboard.", removed))
  end
  self.explorer.renderer:draw()
end

---Copy one or more nodes
---@param node_or_nodes Node|Node[]
function Clipboard:copy(node_or_nodes)
  if node_or_nodes.is then
    utils.array_remove(self.data.cut, node_or_nodes)
    toggle(node_or_nodes, self.data.copy)
    self.explorer.renderer:draw()
  else
    self:bulk_clipboard(utils.filter_descendant_nodes(node_or_nodes), self.data.cut, self.data.copy, "added to")
  end
end

---Cut one or more nodes
---@param node_or_nodes Node|Node[]
function Clipboard:cut(node_or_nodes)
  if node_or_nodes.is then
    utils.array_remove(self.data.copy, node_or_nodes)
    toggle(node_or_nodes, self.data.cut)
    self.explorer.renderer:draw()
  else
    self:bulk_clipboard(utils.filter_descendant_nodes(node_or_nodes), self.data.copy, self.data.cut, "cut to")
  end
end

---Clear clipboard for action and reload if needed.
---@private
---@param action ClipboardAction
function Clipboard:finish_paste(action)
  self.data[action] = {}
  if not self.explorer.opts.filesystem_watchers.enable then
    self.explorer:reload_explorer()
  end
  self.explorer.renderer:draw()
end

---Resolve conflicting paste items with a single batch prompt.
---@private
---@param conflict {node: Node, dest: string}[]
---@param destination string
---@param action ClipboardAction
---@param action_fn ClipboardActionFn
function Clipboard:resolve_conflicts(conflict, destination, action, action_fn)
  local prompt_select = #conflict .. " file(s) already exist"
  local prompt_input = prompt_select .. ". R(ename suffix)/y/n: "

  lib.prompt(prompt_input, prompt_select,
    { "", "y", "n" },
    { "Rename (suffix)", "Overwrite all", "Skip all" },
    "nvimtree_paste_conflict",
    function(item_short)
      utils.clear_prompt()
      if item_short == "y" then
        for _, item in ipairs(conflict) do
          do_paste_one(item.node.absolute_path, item.dest, action, action_fn)
        end
        self:finish_paste(action)
      elseif item_short == "" or item_short == "r" then
        vim.ui.input({ prompt = "Suffix: " }, function(suffix)
          utils.clear_prompt()
          if not suffix or suffix == "" then
            return
          end
          local still_conflict = {}
          for _, item in ipairs(conflict) do
            local basename = vim.fn.fnamemodify(item.node.name, ":r")
            local extension = vim.fn.fnamemodify(item.node.name, ":e")
            local new_name = extension ~= "" and (basename .. suffix .. "." .. extension) or (item.node.name .. suffix)
            local new_dest = utils.path_join({ destination, new_name })
            local stats = vim.loop.fs_stat(new_dest)
            if stats then
              table.insert(still_conflict, { node = item.node, dest = new_dest })
            else
              do_paste_one(item.node.absolute_path, new_dest, action, action_fn)
            end
          end
          if #still_conflict > 0 then
            self:resolve_conflicts(still_conflict, destination, action, action_fn)
          else
            self:finish_paste(action)
          end
        end)
      else
        self:finish_paste(action)
      end
    end)
end

---Paste cut or copy with batch conflict resolution.
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

  -- Partition into conflict / no-conflict
  local no_conflict = {}
  local conflict = {}
  for _, _node in ipairs(clip) do
    local dest = utils.path_join({ destination, _node.name })
    local dest_stats = vim.loop.fs_stat(dest)
    if dest_stats then
      table.insert(conflict, { node = _node, dest = dest })
    else
      table.insert(no_conflict, { node = _node, dest = dest })
    end
  end

  -- Paste non-conflicting items immediately
  for _, item in ipairs(no_conflict) do
    do_paste_one(item.node.absolute_path, item.dest, action, action_fn)
  end

  -- Resolve conflicts in batch
  if #conflict > 0 then
    self:resolve_conflicts(conflict, destination, action, action_fn)
  else
    self:finish_paste(action)
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
