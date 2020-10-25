local M = {}

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
      hl = {}
    else
      padding = string.rep('  ', depth)
    end
  end

  return padding, hl
end

local function format_node(lines, highlights, node, depth, last_node)
  local padding, padding_hl = get_padding(depth, last_node)
  if padding_hl then
    table.insert(highlights, padding_hl)
  end

  -- if node.children then
  -- elseif node.link_to then
  -- else
  -- end

  table.insert(lines, padding..node.name)
end

local function walk(lines, highlights, children, depth)
  for i, node in ipairs(children) do
    format_node(lines, highlights, node, depth, i == #children)
    if node.opened and #node.entries > 0 then
      walk(lines, highlights, node.entries, depth + 1)
    end
  end
end

function M.format_nodes(node_tree)
  local lines = {}
  local highlights = {}
  walk(lines, highlights, node_tree, 0)

  return lines, vim.tbl_flatten(highlights)
end

function M.configure(opts)
  M.config = {
    show_indent_markers = opts.show_indent_markers
  }
end

return M
