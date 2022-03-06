local a = vim.api
local uv = vim.loop

local lib = require "nvim-tree.lib"
local utils = require "nvim-tree.utils"
local events = require "nvim-tree.events"

local M = {}

function M.fn(with_sub)
  return function(node)
    node = lib.get_last_group_node(node)
    if node.name == ".." then
      return
    end

    local namelen = node.name:len()
    local abs_path = with_sub and node.absolute_path:sub(0, namelen * -1 - 1) or node.absolute_path
    local new_name = vim.fn.input("Rename " .. node.name .. " to ", abs_path)
    utils.clear_prompt()
    if not new_name or #new_name == 0 then
      return
    end
    if utils.file_exists(new_name) then
      utils.warn "Cannot rename: file already exists"
      return
    end

    local success = uv.fs_rename(node.absolute_path, new_name)
    if not success then
      return a.nvim_err_writeln("Could not rename " .. node.absolute_path .. " to " .. new_name)
    end
    a.nvim_out_write(node.absolute_path .. " ➜ " .. new_name .. "\n")
    utils.rename_loaded_buffers(node.absolute_path, new_name)
    events._dispatch_node_renamed(abs_path, new_name)
    require("nvim-tree.actions.reloaders").reload_explorer()
  end
end

return M
