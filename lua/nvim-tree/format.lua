local M = {}

-- todo: fix this for indent markers
-- this wont work when having
-- |
-- |_
--   |_
--     |_
local function get_padding(depth, last_node)
  local padding = ""
  local hl = nil
  if depth > 0 then
    if M.config.show_indent_markers then
      if last_node then
        padding = string.rep('│ ', depth-1)..'└ '
      else
        padding = string.rep('│ ', depth)
      end
      hl = "NvimTreeIndentMarker"
    else
      padding = string.rep('  ', depth)
    end
  end

  return padding, hl
end

-- TODO: fix weird extmarks rendering
local function format_node(lines, highlights, node, depth, row, last_node)
  local padding, padding_hl = get_padding(depth, last_node)
  local start_of_text = depth * 2
  if padding_hl then
    table.insert(highlights, {
      line = row,
      col = 0,
      end_col = start_of_text - 1,
      group = padding_hl
    })
  end

  if node.entries then
    table.insert(highlights, {
      line = row,
      col = start_of_text,
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

  local function iter(entries, depth)
    for i, node in ipairs(entries) do
      format_node(lines, highlights, node, depth, idx, i == #entries)
      idx = idx + 1
      if node.opened and #node.entries > 0 then
        iter(node.entries, depth + 1)
      end
    end
  end

  return iter(e, 0)
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
