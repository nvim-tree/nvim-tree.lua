local M = {}

function M.get_padding(depth)
  return string.rep(" ", depth)
end

local function get_padding_arrows(icon_state)
  return function(depth, _, _, node)
    if node.nodes then
      local icon = icon_state.icons.folder_icons[node.open and "arrow_open" or "arrow_closed"]
      return string.rep(" ", depth - 2) .. icon .. " "
    end
    return string.rep(" ", depth)
  end
end

local function get_padding_indent_markers(depth, idx, tree, _, markers)
  local padding = ""
  if depth ~= 0 then
    local rdepth = depth / 2
    markers[rdepth] = idx ~= #tree.nodes
    for i = 1, rdepth do
      if idx == #tree.nodes and i == rdepth then
        padding = padding .. "└ "
      elseif markers[i] then
        padding = padding .. "│ "
      else
        padding = padding .. "  "
      end
    end
  end
  return padding
end

function M.reload_padding_function()
  local icon_state = require("nvim-tree.renderer.icons").get_config()

  if icon_state.show_folder_icon and icon_state.show_folder_arrows then
    M.get_padding = get_padding_arrows(icon_state)
  end

  if vim.g.nvim_tree_indent_markers == 1 then
    M.get_padding = get_padding_indent_markers
  end
end

return M
