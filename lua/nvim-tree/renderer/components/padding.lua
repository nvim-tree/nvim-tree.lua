local M = {}

local function get_padding_indent_markers(depth, idx, nodes_number, markers, with_arrows, node)
  local default_padding = with_arrows and (not node.nodes or depth > 0) and "  " or ""
  local padding = depth == 0 and default_padding or ""

  if depth > 0 then
    local rdepth = depth / 2
    markers[rdepth] = idx ~= nodes_number
    for i = 1, rdepth do
      if idx == nodes_number and i == rdepth then
        padding = padding .. default_padding .. M.config.indent_markers.icons.corner
      elseif markers[i] and i == rdepth then
        padding = padding .. default_padding .. M.config.indent_markers.icons.item
      elseif markers[i] then
        padding = padding .. default_padding .. M.config.indent_markers.icons.edge
      else
        padding = padding .. default_padding .. M.config.indent_markers.icons.none
      end
    end
  end
  return padding
end

local function get_padding_arrows(node, indent)
  if node.nodes then
    return M.config.icons.glyphs.folder[node.open and "arrow_open" or "arrow_closed"] .. " "
  elseif indent then
    return "  "
  else
    return ""
  end
end

function M.get_padding(depth, idx, nodes_number, node, markers)
  local padding = ""

  local show_arrows = M.config.icons.show.folder_arrow
  local show_markers = M.config.indent_markers.enable

  if show_markers then
    padding = padding .. get_padding_indent_markers(depth, idx, nodes_number, markers, show_arrows, node)
  else
    padding = padding .. string.rep(" ", depth)
  end

  if show_arrows then
    padding = padding .. get_padding_arrows(node, not show_markers)
  end

  return padding
end

function M.setup(opts)
  M.config = opts.renderer
end

return M
