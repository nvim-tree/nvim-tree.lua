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

local file_highlights = {
  jpg = "NvimTreeImageFile",
  jpeg = "NvimTreeImageFile",
  png = "NvimTreeImageFile",
  gif = "NvimTreeImageFile",
  ["Cargo.toml"] = "NvimTreeSpecialFile",
  Makefile =  "NvimTreeSpecialFile",
  ["README.md"] = "NvimTreeSpecialFile",
  ["readme.md"] = "NvimTreeSpecialFile",
}

-- TODO: fix shouldn't add icon on special files (readme, cargo.toml) and executables
-- but only on zshrc. Not sure there
local function format_node(lines, highlights, node, depth, row, markers)
  local padding, padding_hl = get_padding(depth, markers)
  local text_start = string.len(padding)
  if padding_hl then
    table.insert(highlights, {
      line = row,
      start_col = 0,
      end_col = text_start,
      group = padding_hl
    })
  end

  local icon = ""
  if node.entries then
    if M.config.show_folder then
      icon = (node.opened and M.config.folders.opened or M.config.folders.closed).." "
      local icon_len = string.len(icon)
      table.insert(highlights, {
        line = row,
        start_col = text_start,
        end_col = text_start + icon_len,
        group = "NvimTreeFolderIcon"
      })
      text_start = text_start + string.len(icon)
    end
    table.insert(highlights, {
      line = row,
      start_col = text_start,
      end_col = text_start + string.len(node.name),
      group = "NvimTreeFolderName"
    })
  elseif node.link_to then
    icon = M.config.symlink_icon.." "
    table.insert(highlights, {
      line = row,
      start_col = text_start,
      end_col = text_start + string.len(node.name),
      group = "NvimTreeSymlink"
    })
  else
    local ext = vim.fn.fnamemodify(node.name, ':e') or ""
    if M.config.show_icons then
      local i, hl = require'nvim-web-devicons'.get_icon(node.name, ext, {default = M.config.show_default})
      if i then
        icon = i..' '
        local icon_len = string.len(icon)
        table.insert(highlights, {
          line = row,
          start_col = text_start,
          end_col = text_start + icon_len,
          group = hl
        })
        text_start = text_start + icon_len
      end
    end

    local text_length = string.len(node.name)
    local custom_file_hl = file_highlights[node.name] or file_highlights[ext]
    if vim.fn.executable(node.absolute_path) == 1 then
      table.insert(highlights, {
        line = row,
        start_col = text_start,
        end_col = text_start + text_length,
        group = "NvimTreeExecFile"
      })
    elseif custom_file_hl then
      table.insert(highlights, {
        line = row,
        start_col = text_start,
        end_col = text_start + text_length,
        group = custom_file_hl
      })
    end
  end

  table.insert(lines, padding..icon..node.name)
end

local function walk(lines, highlights, e)
  local idx = 1

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

function M.format_nodes(node_tree, cwd)
  local modifier = M.config.root_folder_modifier or ':~'
  local lines = {vim.fn.fnamemodify(cwd, modifier):gsub('/$', '').."/.."}
  local highlights = {{
    line = 0,
    start_col = 0,
    end_col = #lines[1],
    group = "NvimTreeRootFolder"
  }}
  walk(lines, highlights, node_tree)

  return lines, highlights
end

function M.configure(opts)
  M.config = {
    show_indent_markers = opts.show_indent_markers,
    show_folder = opts.folders.show,
    folders = opts.folders.icons,
    symlink_icon = opts.simlink_icon,
    show_icons = opts.web_devicons.show,
    show_default = opts.web_devicons.default
  }
end

return M
