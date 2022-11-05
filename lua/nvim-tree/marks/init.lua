local view = require "nvim-tree.view"
local Iterator = require "nvim-tree.iterators.node-iterator"
local core = require "nvim-tree.core"

local NvimTreeMarks = {}

local M = {}

local function add_mark(node)
  NvimTreeMarks[node.absolute_path] = node
  M.draw()
end

local function remove_mark(node)
  NvimTreeMarks[node.absolute_path] = nil
  M.draw()
end

function M.toggle_mark(node)
  if node.absolute_path == nil then
    return
  end

  if M.get_mark(node) then
    remove_mark(node)
  else
    add_mark(node)
  end
end

function M.clear_marks()
  NvimTreeMarks = {}
  M.draw()
end

function M.get_mark(node)
  return NvimTreeMarks[node.absolute_path]
end

function M.get_marks()
  local list = {}
  for _, node in pairs(NvimTreeMarks) do
    table.insert(list, node)
  end
  return list
end

local GROUP = "NvimTreeMarkSigns"
local SIGN_NAME = "NvimTreeMark"

function M.clear()
  vim.fn.sign_unplace(GROUP)
end

function M.draw()
  if not view.is_visible() then
    return
  end

  M.clear()

  local buf = view.get_bufnr()
  local add = core.get_nodes_starting_line() - 1
  Iterator.builder(core.get_explorer().nodes)
    :recursor(function(node)
      return node.open and node.nodes
    end)
    :applier(function(node, idx)
      if M.get_mark(node) then
        vim.fn.sign_place(0, GROUP, SIGN_NAME, buf, { lnum = idx + add, priority = 3 })
      end
    end)
    :iterate()
end

function M.setup(opts)
  vim.fn.sign_define(SIGN_NAME, { text = opts.renderer.icons.glyphs.bookmark, texthl = "NvimTreeBookmark" })
  require("nvim-tree.marks.bulk-move").setup(opts)
end

return M
