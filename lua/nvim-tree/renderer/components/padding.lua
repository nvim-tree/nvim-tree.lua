local M = {}

function M.get_padding(depth)
  return string.rep(" ", depth)
end

local function get_padding_arrows()
  return function(depth, _, _, node)
    if node.nodes then
      local icon = M.config.icons.glyphs.folder[node.open and "arrow_open" or "arrow_closed"]
      return string.rep(" ", depth - 2) .. icon .. " "
    end
    return string.rep(" ", depth)
  end
end

local function get_padding_indent_markers(depth, idx, nodes_number, _, markers)
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

function M.reload_padding_function()
  if M.config.icons.show.folder and M.config.icons.show.folder_arrow then
    M.get_padding = get_padding_arrows()
  end

  if M.config.indent_markers.enable then
    M.get_padding = get_padding_indent_markers
  end
end

function M.setup(opts)
  M.config = opts.renderer
end

return M
