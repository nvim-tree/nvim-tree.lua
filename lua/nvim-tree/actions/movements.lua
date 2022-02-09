local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local diagnostics = require'nvim-tree.diagnostics'
local _icons = require"nvim-tree.renderer.icons"
local renderer = require"nvim-tree.renderer"
local lib = function() return require'nvim-tree.lib' end

local M = {}

local function get_line_from_node(node, find_parent)
  local node_path = node.absolute_path

  if find_parent then
    node_path = node.absolute_path:match("(.*)"..utils.path_separator)
  end

  local line = 2
  local function iter(nodes, recursive)
    for _, _node in ipairs(nodes) do
      local n = lib().get_last_group_node(_node)
      if node_path == n.absolute_path then
        return line, _node
      end

      line = line + 1
      if _node.open == true and recursive then
        local _, child = iter(_node.nodes, recursive)
        if child ~= nil then return line, child end
      end
    end
  end
  return iter
end


function M.parent_node(should_close)
  return function(node)
    if node.name == '..' then return end

    should_close = should_close or false
    local altered_tree = false

    local iter = get_line_from_node(node, true)
    if node.open == true and should_close then
      node.open = false
      altered_tree = true
    else
      local line, parent = iter(TreeExplorer.nodes, true)
      if parent == nil then
        line = 1
      elseif should_close then
        parent.open = false
        altered_tree = true
      end
      line = view.View.hide_root_folder and line - 1 or line
      view.set_cursor({line, 0})
    end

    if altered_tree then
      diagnostics.update()
      renderer.draw()
    end
  end
end

function M.sibling(direction)
  return function(node)
    if node.name == '..' or not direction then return end

    local iter = get_line_from_node(node, true)
    local node_path = node.absolute_path

    local line = 0
    local parent, _

    -- Check if current node is already at root nodes
    for index, _node in ipairs(TreeExplorer.nodes) do
      if node_path == _node.absolute_path then
        line = index
      end
    end

    if line > 0 then
      parent = TreeExplorer
    else
      _, parent = iter(TreeExplorer.nodes, true)
      if parent ~= nil and #parent.nodes > 1 then
        line, _ = get_line_from_node(node)(parent.nodes)
      end

      -- Ignore parent line count
      line = line - 1
    end

    local index = line + direction
    if index < 1 then
      index = 1
    elseif index > #parent.nodes then
      index = #parent.nodes
    end
    local target_node = parent.nodes[index]

    line, _ = get_line_from_node(target_node)(TreeExplorer.nodes, true)
    view.set_cursor({line, 0})
  end
end

function M.find_git_item(where)
  local icon_state = _icons.get_config()
  local flags = where == 'next' and 'b' or ''
  local icons = table.concat(vim.tbl_values(icon_state.icons.git_icons), '\\|')
  return function()
    return icon_state.show_git_icon and vim.fn.search(icons, flags)
  end
end

return M
