local log = require("nvim-tree.log")
local utils = require("nvim-tree.utils")
local core = require("nvim-tree.core")

local DirectoryNode = require("nvim-tree.node.directory")
local Iterator = require("nvim-tree.iterators.node-iterator")

local M = {}

local running = {}

---Find a path in the tree, expand it and focus it
---@param path string relative or absolute
function M.fn(path)
  local explorer = core.get_explorer()
  if not explorer or not explorer.view:is_visible() then
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
    explorer:refresh_parent_nodes_for_path(vim.fn.fnamemodify(path_real, ":h"))
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
        local dir = node:as(DirectoryNode)
        if dir then
          if not dir.group_next then
            dir.open = true
          end
          if #dir.nodes == 0 then
            core.get_explorer():expand(dir)
            if dir.group_next and incremented_line then
              line = line - 1
            end
          end
        end
      end
    end)
    :recursor(function(node)
      node = node and node:as(DirectoryNode)
      if node then
        return node.group_next and { node.group_next } or (node.open and #node.nodes > 0 and node.nodes)
      else
        return nil
      end
    end)
    :iterate()

  if found and explorer.view:is_visible() then
    explorer.renderer:draw()
    explorer.view:set_cursor({ line, 0 })
  end

  running[path_real] = false

  log.profile_end(profile)
end

return M
