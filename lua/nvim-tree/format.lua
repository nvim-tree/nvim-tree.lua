local M = {}

local function get_padding(depth, markers)
  local padding = ""
  local hl = nil
  if depth > 0 then
    if markers then
      padding = markers
      hl = "NvimTreeIndentMarker"
    else
      padding = string.rep('  ', depth)
    end
  end

  return padding, hl
end

local function format_node(lines, highlights, node, depth, row, markers)
  local padding, padding_hl = get_padding(depth, markers)
  local start_of_text = string.len(padding)
  if padding_hl then
    table.insert(highlights, {
      line = row,
      start_col = 0,
      end_col = start_of_text,
      group = padding_hl
    })
  end

  if node.entries then
    table.insert(highlights, {
      line = row,
      start_col = start_of_text,
      end_col = start_of_text + #node.name,
      group = "NvimTreeFolderName"
    })
  -- elseif node.link_to then
  -- else
  end

  table.insert(lines, padding..node.name)
end

local function walk(lines, highlights, e)
  local idx = 0

  local function iter(entries, depth, markers)
    if markers and depth > 0 then markers = markers..'│ ' end

    for i, node in ipairs(entries) do
      local last_node = markers and i == #entries and depth > 0
      if last_node then markers = markers:gsub('│ $', '└ ') end

      format_node(lines, highlights, node, depth, idx, markers)
      if last_node then markers = markers:gsub('└ $', '  ') end

      idx = idx + 1
      if node.opened and #node.entries > 0 then
        iter(node.entries, depth + 1, markers)
      end
    end
  end

  return iter(e, 0, M.config.show_indent_markers and "" or nil)
end

function M.format_nodes(node_tree)
  local lines = {}
  local highlights = {}
  walk(lines, highlights, node_tree)

  return lines, highlights
end

function M.configure(opts)
  M.config = {
    show_indent_markers = opts.show_indent_markers
  }
end

return M
