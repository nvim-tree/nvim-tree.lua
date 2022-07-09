local M = {}

local function get_padding_indent_markers(depth, idx, nodes_number, markers)
  local padding = ""

  if depth ~= 0 then
    local rdepth = depth / 2
    markers[rdepth] = idx ~= nodes_number
    for i = 1, rdepth do
      if idx == nodes_number and i == rdepth then
        padding = padding .. M.config.indent_markers.icons.corner
      elseif markers[i] and i == rdepth then
        padding = padding .. M.config.indent_markers.icons.item
      elseif markers[i] then
        padding = padding .. M.config.indent_markers.icons.edge
      else
        padding = padding .. M.config.indent_markers.icons.none
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

  if M.config.indent_markers.enable then
    padding = padding .. get_padding_indent_markers(depth, idx, nodes_number, markers)
  else
    padding = padding .. string.rep(" ", depth)
  end

  if M.config.icons.show.folder_arrow then
    padding = padding .. get_padding_arrows(node, not M.config.indent_markers.enable)
  end

  return padding
end

function M.setup(opts)
  M.config = opts.renderer
end

return M
