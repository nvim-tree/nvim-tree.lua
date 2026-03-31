local config = require("nvim-tree.config")
local DirectoryNode = require("nvim-tree.node.directory")

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

local function get_padding_indent_markers(depth, idx, nodes_number, markers, with_arrows, inline_arrows, node, early_stop)
  local base_padding = with_arrows and (not node.nodes or depth > 0) and "  " or ""
  local padding = (inline_arrows or depth == 0) and base_padding or ""

  if depth > 0 then
    local has_folder_sibling = check_siblings_for_folder(node, with_arrows)
    local indent = string.rep(" ", config.g.renderer.indent_width - 1)
    markers[depth] = idx ~= nodes_number
    for i = 1, depth - early_stop do
      local glyph
      if idx == nodes_number and i == depth then
        local bottom_width = config.g.renderer.indent_width - 2 + (with_arrows and not inline_arrows and has_folder_sibling and 2 or 0)
        glyph = config.g.renderer.indent_markers.icons.corner
          .. string.rep(config.g.renderer.indent_markers.icons.bottom, bottom_width)
          .. (config.g.renderer.indent_width > 1 and " " or "")
      elseif markers[i] and i == depth then
        glyph = config.g.renderer.indent_markers.icons.item .. indent
      elseif markers[i] then
        glyph = config.g.renderer.indent_markers.icons.edge .. indent
      else
        glyph = config.g.renderer.indent_markers.icons.none .. indent
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

---@param depth integer
---@param idx integer
---@param nodes_number integer
---@param node Node
---@param markers table
---@param early_stop integer?
---@return nvim_tree.api.highlighted_string
function M.get_indent_markers(depth, idx, nodes_number, node, markers, early_stop)
  local str = ""

  local show_arrows = config.g.renderer.icons.show.folder_arrow
  local show_markers = config.g.renderer.indent_markers.enable
  local inline_arrows = config.g.renderer.indent_markers.inline_arrows
  local indent_width = config.g.renderer.indent_width

  if show_markers then
    str = str .. get_padding_indent_markers(depth, idx, nodes_number, markers, show_arrows, inline_arrows, node, early_stop or 0)
  else
    str = str .. string.rep(" ", depth * indent_width)
  end

  return { str = str, hl = { "NvimTreeIndentMarker" } }
end

---@param node Node
---@return nvim_tree.api.highlighted_string[]?
function M.get_arrows(node)
  if not config.g.renderer.icons.show.folder_arrow then
    return
  end

  local str
  local hl = "NvimTreeFolderArrowClosed"

  local dir = node:as(DirectoryNode)
  if dir then
    if dir.open then
      str = config.g.renderer.icons.glyphs.folder["arrow_open"] .. config.g.renderer.icons.padding.folder_arrow
      hl = "NvimTreeFolderArrowOpen"
    else
      str = config.g.renderer.icons.glyphs.folder["arrow_closed"] .. config.g.renderer.icons.padding.folder_arrow
    end
  elseif config.g.renderer.indent_markers.enable then
    str = ""
  else
    str = " " .. string.rep(" ", #config.g.renderer.icons.padding.folder_arrow)
  end

  return { str = str, hl = { hl } }
end

return M
