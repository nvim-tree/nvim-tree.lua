local M = {}

local function check_siblings_for_folder(node, with_arrows)
  if with_arrows then
    local has_files = false
    local has_folders = false
    for _, n in pairs(node.parent.nodes) do
      if n.nodes and node.absolute_path ~= n.absolute_path then
        has_folders = true
      end
      if not n.nodes then
        has_files = true
      end
      if has_files and has_folders then
        return true
      end
    end
  end
  return false
end

local function get_padding_indent_markers(depth, idx, nodes_number, markers, with_arrows, inline_arrows, node)
  local base_padding = with_arrows and (not node.nodes or depth > 0) and "  " or ""
  local padding = (inline_arrows or depth == 0) and base_padding or ""

  if depth > 0 then
    local has_folder_sibling = check_siblings_for_folder(node, with_arrows)
    local indent = string.rep(" ", M.config.indent_width - 1)
    markers[depth] = idx ~= nodes_number
    for i = 1, depth do
      local glyph
      if idx == nodes_number and i == depth then
        local bottom_width = M.config.indent_width
          - 2
          + (with_arrows and not inline_arrows and has_folder_sibling and 2 or 0)
        glyph = M.config.indent_markers.icons.corner
          .. string.rep(M.config.indent_markers.icons.bottom, bottom_width)
          .. (M.config.indent_width > 1 and " " or "")
      elseif markers[i] and i == depth then
        glyph = M.config.indent_markers.icons.item .. indent
      elseif markers[i] then
        glyph = M.config.indent_markers.icons.edge .. indent
      else
        glyph = M.config.indent_markers.icons.none .. indent
      end

      if not with_arrows or (inline_arrows and (depth ~= i or not node.nodes)) then
        padding = padding .. glyph
      elseif inline_arrows then
        padding = padding
      elseif idx ~= nodes_number and depth == i and not node.nodes and has_folder_sibling then
        padding = padding .. base_padding .. glyph .. base_padding
      else
        padding = padding .. base_padding .. glyph
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
  local inline_arrows = M.config.indent_markers.inline_arrows
  local indent_width = M.config.indent_width

  if show_markers then
    padding = padding .. get_padding_indent_markers(depth, idx, nodes_number, markers, show_arrows, inline_arrows, node)
  else
    padding = padding .. string.rep(" ", depth * indent_width)
  end

  if show_arrows then
    padding = padding .. get_padding_arrows(node, not show_markers)
  end

  return padding
end

function M.setup(opts)
  M.config = opts.renderer

  if M.config.indent_width < 1 then
    M.config.indent_width = 1
  end

  local function check_marker(symbol)
    if #symbol == 0 then
      return " "
    end
    -- return the first character from the UTF-8 encoded string; we may use utf8.codes from Lua 5.3 when available
    return symbol:match "[%z\1-\127\194-\244][\128-\191]*"
  end

  for k, v in pairs(M.config.indent_markers.icons) do
    M.config.indent_markers.icons[k] = check_marker(v)
  end
end

return M
