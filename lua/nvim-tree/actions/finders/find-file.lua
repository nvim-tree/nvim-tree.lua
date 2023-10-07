local log = require "nvim-tree.log"
local view = require "nvim-tree.view"
local utils = require "nvim-tree.utils"
local renderer = require "nvim-tree.renderer"
local reload = require "nvim-tree.explorer.reload"
local core = require "nvim-tree.core"
local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {}

local running = {}

---Find a path in the tree, expand it and focus it
---@param path string relative or absolute
function M.fn(path)
  if not core.get_explorer() or not view.is_visible() then
    return
  end

  -- always match against the real path
  local path_real = vim.loop.fs_realpath(path)
  if not path_real then
    return
  end

  if running[path_real] then
    return
  end
  running[path_real] = true

  local profile = log.profile_start("find file %s", path_real)

  -- refresh the contents of all parents, expanding groups as needed
  if utils.get_node_from_path(path_real) == nil then
    reload.refresh_parent_nodes_for_path(vim.fn.fnamemodify(path_real, ":h"))
  end

  local line = core.get_nodes_starting_line()

  local absolute_paths_searched = {}

  local found = Iterator.builder(core.get_explorer().nodes)
    :matcher(function(node)
      return node.absolute_path == path_real or node.link_to == path_real
    end)
    :applier(function(node)
      local incremented_line = false
      if not node.group_next then
        line = line + 1
        incremented_line = true
      end

      if vim.tbl_contains(absolute_paths_searched, node.absolute_path) then
        return
      end
      table.insert(absolute_paths_searched, node.absolute_path)

      local abs_match = vim.startswith(path_real, node.absolute_path .. utils.path_separator)
      local link_match = node.link_to and vim.startswith(path_real, node.link_to .. utils.path_separator)

      if abs_match or link_match then
        if not node.group_next then
          node.open = true
        end
        if #node.nodes == 0 then
          core.get_explorer():expand(node)
          if node.group_next and incremented_line then
            line = line - 1
          end
        end
      end
    end)
    :recursor(function(node)
      return node.group_next and { node.group_next } or (node.open and #node.nodes > 0 and node.nodes)
    end)
    :iterate()

  if found and view.is_visible() then
    renderer.draw()
    view.set_cursor { line, 0 }
  end

  running[path_real] = false

  log.profile_end(profile)
end

return M
