local log = require "nvim-tree.log"
local view = require "nvim-tree.view"
local utils = require "nvim-tree.utils"
local renderer = require "nvim-tree.renderer"
local core = require "nvim-tree.core"
local Iterator = require "nvim-tree.iterators.node-iterator"

local M = {}

local running = {}

---Find a path in the tree, expand it and focus it
---@param fname string full path
function M.fn(fname)
  if running[fname] or not core.get_explorer() then
    return
  end

  -- always match against the real path
  local fname_real = vim.loop.fs_realpath(fname)
  if not fname_real then
    return
  end

  running[fname] = true

  local ps = log.profile_start("find file %s", fname)

  -- first line is the root node
  local line = core.get_nodes_starting_line() - 1

  local absolute_paths_searched = {}

  local found = Iterator.builder({ core.get_explorer() })
    :matcher(function(node)
      return node.absolute_path == fname_real or node.link_to == fname_real
    end)
    :applier(function(node)
      line = line + 1

      if vim.tbl_contains(absolute_paths_searched, node.absolute_path) then
        return
      end
      table.insert(absolute_paths_searched, node.absolute_path)

      local abs_match = vim.startswith(fname_real, node.absolute_path .. utils.path_separator)
      local link_match = node.link_to and vim.startswith(fname_real, node.link_to .. utils.path_separator)

      if abs_match or link_match then
        node.open = true
        core.get_explorer():expand(node)
      end
    end)
    :recursor(function(node)
      return node.open and node.nodes
    end)
    :iterate()

  if found and view.is_visible() then
    renderer.draw()
    view.set_cursor { line, 0 }
  end

  running[fname] = false

  log.profile_end(ps, "find file %s", fname)
end

return M
