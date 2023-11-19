--- @diagnostic disable: redefined-local
local lib = require "nvim-tree.lib"
local log = require "nvim-tree.log"
local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local events = require "nvim-tree.events"
local notify = require "nvim-tree.notify"
local renderer = require "nvim-tree.renderer"
local reloaders = require "nvim-tree.actions.reloaders.reloaders"
local fs_copypaste = require "nvim-tree.actions.fs.copy-paste"
local fs_rename = require "nvim-tree.actions.fs.rename-file"
local actions_fs_remove = require("nvim-tree.actions.fs.remove-file").fn
local git = require "nvim-tree.git.cli"
local Set = require "nvim-tree.std.Set"
local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local utils_ui = require "nvim-tree.utils-ui"
local find_file = require("nvim-tree.actions.finders.find-file").fn

local M = {}

M.config = {}
M.config.git = {}

-- Reexport basic classes and instances
M.Set = Set
M.git = git

--- @class ClipboardInstance:SetInstance
--- @field clear fun(self): nil clear clipboard content
--- @field print fun(self): nil print clipboard content

-- Export clipboard namespace used to keep list of nodes to be renamed
M.clipboard = {}

-- Clipboard for cutting
-- TODO: replace by global clipboard
M.clipboard.cut = M.Set:new() --[[@as ClipboardInstance]]
function M.clipboard.clear()
  notify.info(("Clipboard: emptied, %s items removed"):format(#M.clipboard.cut))
  log.line("action_git", "clipboard cleared")
  M.cplipboard.cut:clear()
  renderer.draw()
end

--- Print content of a clipboard
--- @return nil
function M.clipboard.print()
  local clipboard = M.clipboard.cut
  local content = { "cut" }
  for _, node in ipairs(clipboard) do
    if type(node.absolute_path) == "string" then
      table.insert(content, " * " .. (notify.render_path(node.absolute_path)))
    end
  end
  return notify.info(table.concat(content, "\n") .. "\n")
end

--- Add node to the cut clipboard to be moved to another destination by git mv
M.cut = function(node)
  if node.name == ".." then
    return
  end
  local git_opts = { timeout = M.config.git.timeout }
  return M.git.is_tracked(node.absolute_path, git_opts, function(err, data)
    if err then
      -- if file isn't tracked, fallback to fs.copy-paste.cut
      vim.defer_fn(function()
        fs_copypaste.cut(node)
      end, 0)
      log.line("action_git", "cut has failed %s", err)
    elseif data then
      if data:match "^error:.*" or data:match "^fatal:.*" then
        log.line("action_git", "cut (git mv) has failed %s", data)
        vim.defer_fn(function()
          fs_copypaste.cut(node)
        end, 0)
      else
        if M.clipboard.cut:has(node) then
          notify.info(notify.render_path(node.absolute_path) .. " removed from clipboard.")
          M.clipboard.cut:del(node)
        else
          notify.info(notify.render_path(node.absolute_path) .. " added to clipboard.")
          M.clipboard.cut:set(node)
        end
        renderer.draw()
      end
    end
  end)
end -- M.cut

-- Delete given node by using git rm
M.delete = function(node)
  if node.name == ".." then
    return
  end
  local git_opts = { timeout = M.config.git.timeout }
  events._dispatch_will_remove_file(node.absolute_path)
  return M.git.rm(node.absolute_path, git_opts, function(err, data)
    local notify_path = notify.render_path(node.absolute_path)
    if err or (data and (data:match "^error:.*" or data:match "^fatal:.*")) then
      vim.defer_fn(function()
        actions_fs_remove(node)
      end, 0)
      log.line("action_git", "failed to remove %s", err)
    elseif not err and data then
      events._dispatch_file_removed(node.absolute_path)
      notify.info(notify_path .. " was properly removed.")
      renderer.draw()
    end
  end)
end -- M.delete

--- Number of clipboard items most recently pasted by M.paste()
--- Reset every time M.paste() is called
--- @type number
M.pasted = 0

--- Paste saved by cut()/copy() items to the given node destination
--- @param node_dst table
--- @param clipboard ClipboardInstance|nil
--- @return nil
function M.paste(node_dst, clipboard)
  clipboard = clipboard or M.clipboard.cut
  if #clipboard == 0 then
    fs_copypaste.paste(node_dst)
    return
  end

  node_dst = lib.get_last_group_node(node_dst)
  if node_dst.name == ".." then
    node_dst = core.get_explorer()
  end

  local path_dst = node_dst.absolute_path
  local stats, errmsg, errcode = vim.loop.fs_stat(path_dst)
  if not stats and errcode ~= "ENOENT" then
    log.line("action_git", "paste of '%s' failed: %s", path_dst, errmsg)
    notify.error("pasting failed" .. notify.render_path(path_dst) .. " - " .. (errmsg or "???"))
    return
  end

  local fnamemodify = vim.fn.fnamemodify
  local node_dst_path_dir = fnamemodify(node_dst.absolute_path, ":p:h")
  local dir_dst = stats.type == "directory" and path_dst or node_dst_path_dir

  -- Number of times content of a clipboard was pasted
  local clip_pasted = 0
  for clip_indx, node_src in ipairs(clipboard) do
    local path_src = fnamemodify(node_src.absolute_path, ":p")
    path_dst = utils.path_join { dir_dst, node_src.name }
    local notify_dst = notify.render_path(path_dst)
    local notify_src = notify.render_path(node_src.absolute_path)

    -- if filename is the same in dest
    if node_src.name == node_dst.name then
      log.line("action_git", "%s -> %s: paste skip: same source and destination name", path_src, path_dst)
      print(("%s: similarly named file!"):format(debug.getinfo(1).source))
      events._dispatch_will_rename_node(path_src, path_dst)
      -- TODO: use lib.prompt?
      notify.warn(("Cannot paste %s -> %s: file already exists. Aborting."):format(notify_src, notify_dst))
    else
      events._dispatch_will_rename_node(path_src, path_dst)
      local git_opts = { timeout = M.config.git.timeout }
      M.git.mv(path_src, path_dst, git_opts, function(err, data)
        if err then
          log.line("action_git", "%s -> %s - paste failed %s", notify_src, notify_dst, err)
          notify.error(("git mv failed: %s"):format(data))
        elseif err and (data and (data:match "error:.*" or data:match "fatal:.*")) then
          if data:match "fatal: destination exists.*" then
            -- TODO: use lib.prompt?
            notify.warn(("Cannot paste %s -> %s: file already exists. Aborting."):format(notify_src, notify_dst))
            return
          end
        else
          clip_pasted = clip_pasted + 1
          clipboard[clip_indx] = nil -- clear pasted items

          log.line("action_git", "%s -> %s: moved", node_dst.absolute_path, path_dst)
          notify.info(("%s -> %s"):format(path_src, path_dst))

          utils.rename_loaded_buffers(path_src, path_dst)
          events._dispatch_node_renamed(path_src, path_dst)
        end
      end) -- git mv
    end
  end -- loop

  if clip_pasted > 0 then
    notify.info(("Clipboard: pasted %s paths"):format(clip_pasted))
    M.pasted = clip_pasted
  end

  if not M.config.filesystem_watchers.enable then
    reloaders.reload_explorer()
  end
  -- paste everything in fs copy-paste clipboard
  fs_copypaste.paste(node_dst)
end -- M.paste

--- @class gitPromptForRenameOpts: InputPathEditorOpts
--- @field prompt string|nil string to be used as prompt

--- Prompt user to specify new path by using UI prompt and then use git for rename
--- if git fails, fallback to actions.actions.fs.rename-file routine
--- @param node_src table nvim-tree node instance
--- @param opts gitPromptForRenameOpts options to tweak prompt
function M.prompt_for_rename(node_src, opts)
  local opts_has_fields = opts.filename or opts.basename or opts.absolute or opts.dirname or opts.relative
  if not (opts and opts_has_fields) then
    error "git actions: opts are missing or lack required field"
  end

  if type(node_src) ~= "table" then
    ---@diagnostic disable-next-line: cast-local-type
    node_src = lib.get_node_at_cursor()
  end

  node_src = lib.get_last_group_node(node_src)
  if node_src.name == ".." then
    return
  end

  -- local fnamemodify = vim.fn.fnamemodify
  local prompt_default = utils_ui.Input_path_editor:new(node_src.absolute_path, opts)

  local ui_input_opts = {
    prompt = opts.prompt and opts.prompt or "Rename to ",
    default = prompt_default:prepare(),
    completion = "file",
  }

  vim.ui.input(ui_input_opts, function(path_modified)
    utils.clear_prompt()
    if (not path_modified) or (path_modified == prompt_default) then
      return
    end

    -- Path to rename to; absolute
    local path_dst = prompt_default:restore(path_modified)
    local notify_src = notify.render_path(node_src.absolute_path)
    local notify_dst = notify.render_path(path_dst)

    local git_opts = { timeout = M.config.git.timeout }
    M.git.mv(node_src.absolute_path, path_dst, git_opts, function(err, data)
      -- Optimization: assign only on error
      if err then
        log.line("action_git", "%s -> %s - rename failed %s", notify_src, notify_dst, err)
      elseif not err and (data and (data:match "error:.*" or data:match "fatal:.*")) then
        if data:match "fatal: destination exists.*" then
          notify.warn(("Cannot rename %s -> %s: file already exists. Aborting."):format(notify_src, notify_dst))
          return
        end
        -- When moving (renaming) a versioned file
        -- from a path to the repository (".git" directory)
        -- to the parent folder, fallback to actions.fs.rename-file
        if data:match "fatal: not under version control.*" or data:match "fatal: '.*' is outside repository.*" then
          log.line("action_git", "%s - not versioned by git; falling back to actions.fs.rename-file", notify_src)
          vim.schedule(function()
            fs_rename.rename_node_to(node_src, path_dst)
          end)
          return
        end

        log.line("action_git", "unhandled git error: %s", data, notify_src, notify_dst)
        notify.error(("rename: unhandmed git error: %s"):format(data))
      elseif not err and data then
        log.line("action_git", "%s -> %s: renamed", node_src.absolute_path, path_dst)
        notify.info(string.format("%s -> %s", notify_src, notify_dst))
        utils.rename_loaded_buffers(node_src.absolute_path, path_dst)
        events._dispatch_node_renamed(node_src.absolute_path, path_dst)

        -- focus file in nvim-tree
        find_file(utils.path_remove_trailing(path_dst))

        if not M.config.filesystem_watchers.enable then
          reloaders.reload_explorer()
        end
      end
    end) -- git-mv
  end)

  return node_src
end -- M.prompt_for_rename

-- These functions rename various parts of node's absolute path
function M.rename_basename(node)
  return M.prompt_for_rename(node, { basename = true })
end
function M.rename_absolute(node)
  return M.prompt_for_rename(node, { absolute = true })
end
function M.rename(node)
  return M.prompt_for_rename(node, { filename = true })
end
function M.rename_sub(node)
  return M.prompt_for_rename(node, { dirname = true })
end
function M.rename_relative(node)
  return M.prompt_for_rename(node, { relative = true })
end

-- TODO: Move to global clipboard
---Clipboard text highlight group and position when highlight_clipboard.
---@param node table
---@return HL_POSITION position none when clipboard empty
---@return string|nil group only when node present in clipboard
function M.get_highlight(node)
  if M.hl_pos == HL_POSITION.none then
    return HL_POSITION.none, nil
  end

  for _, n in ipairs(M.clipboard.cut) do
    if node == n then
      return M.hl_pos, "NvimTreeCutHL"
    end
  end

  return HL_POSITION.none, nil
end

function M.setup(opts)
  M.config.filesystem_watchers = opts.filesystem_watchers
  M.config.git.timeout = opts.git.timeout or 4000 -- 4 seconds
  M.hl_pos = HL_POSITION[opts.renderer.highlight_clipboard] or HL_POSITION.none
end

return M
