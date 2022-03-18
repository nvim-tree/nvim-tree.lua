local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"
local _padding = require "nvim-tree.renderer.padding"
local _help = require "nvim-tree.renderer.help"
local _icons = require "nvim-tree.renderer.icons"
local git = require "nvim-tree.renderer.git"
local core = require "nvim-tree.core"

local api = vim.api

local lines = {}
local hl = {}
local index = 0
local namespace_id = api.nvim_create_namespace "NvimTreeHighlights"

local icon_state = _icons.get_config()

local should_hl_opened_files = (vim.g.nvim_tree_highlight_opened_files or 0) ~= 0

local get_folder_icon = function()
  return ""
end
local function get_trailing_length()
  return vim.g.nvim_tree_add_trailing and 1 or 0
end

local set_folder_hl = function(line, depth, git_icon_len, _, hl_group, _)
  table.insert(hl, { hl_group, line, depth + git_icon_len, -1 })
end

local icon_padding = vim.g.nvim_tree_icon_padding or " "

if icon_state.show_folder_icon then
  get_folder_icon = function(open, is_symlink, has_children)
    local n
    if is_symlink and open then
      n = icon_state.icons.folder_icons.symlink_open
    elseif is_symlink then
      n = icon_state.icons.folder_icons.symlink
    elseif open then
      if has_children then
        n = icon_state.icons.folder_icons.open
      else
        n = icon_state.icons.folder_icons.empty_open
      end
    else
      if has_children then
        n = icon_state.icons.folder_icons.default
      else
        n = icon_state.icons.folder_icons.empty
      end
    end
    return n .. icon_padding
  end
  set_folder_hl = function(line, depth, icon_len, name_len, hl_icongroup, hl_fnamegroup)
    local hl_icon = should_hl_opened_files and hl_icongroup or "NvimTreeFolderIcon"
    table.insert(hl, { hl_icon, line, depth, depth + icon_len })
    table.insert(hl, { hl_fnamegroup, line, depth + icon_len, depth + icon_len + name_len + get_trailing_length() })
  end
end

local get_file_icon = function()
  return ""
end
if icon_state.show_file_icon then
  if icon_state.has_devicons then
    local web_devicons = require "nvim-web-devicons"

    get_file_icon = function(fname, extension, line, depth)
      local icon, hl_group = web_devicons.get_icon(fname, extension)

      if icon and hl_group ~= "DevIconDefault" then
        if hl_group then
          table.insert(hl, { hl_group, line, depth, depth + #icon + 1 })
        end
        return icon .. icon_padding
      elseif string.match(extension, "%.(.*)") then
        -- If there are more extensions to the file, try to grab the icon for them recursively
        return get_file_icon(fname, string.match(extension, "%.(.*)"), line, depth)
      else
        return #icon_state.icons.default > 0 and icon_state.icons.default .. icon_padding or ""
      end
    end
  else
    get_file_icon = function()
      return #icon_state.icons.default > 0 and icon_state.icons.default .. icon_padding or ""
    end
  end
end

local get_symlink_icon = function()
  return icon_state.icons.symlink
end
if icon_state.show_file_icon then
  get_symlink_icon = function()
    return #icon_state.icons.symlink > 0 and icon_state.icons.symlink .. icon_padding or ""
  end
end

local get_special_icon = function()
  return ""
end
if icon_state.show_file_icon then
  get_special_icon = function()
    return #icon_state.icons.default > 0 and icon_state.icons.default .. icon_padding or ""
  end
end

local picture = {
  jpg = true,
  jpeg = true,
  png = true,
  gif = true,
}

local function get_special_files_map()
  return vim.g.nvim_tree_special_files
    or {
      ["Cargo.toml"] = true,
      Makefile = true,
      ["README.md"] = true,
      ["readme.md"] = true,
    }
end

local function update_draw_data(tree, depth, markers)
  local special = get_special_files_map()

  for idx, node in ipairs(tree.nodes) do
    local padding = _padding.get_padding(depth, idx, tree, node, markers)
    local offset = string.len(padding)
    if depth > 0 then
      table.insert(hl, { "NvimTreeIndentMarker", index, 0, offset })
    end

    local git_hl = git.get_highlight(node)

    if node.nodes then
      local has_children = #node.nodes ~= 0 or node.has_children
      local icon = get_folder_icon(node.open, node.link_to ~= nil, has_children)
      local git_icon = git.get_icons(node, index, offset, #icon, hl) or ""
      -- INFO: this is mandatory in order to keep gui attributes (bold/italics)
      local folder_hl = "NvimTreeFolderName"
      local name = node.name
      local next = node.group_next
      while next do
        name = name .. "/" .. next.name
        next = next.group_next
      end
      if not has_children then
        folder_hl = "NvimTreeEmptyFolderName"
      end
      if node.open then
        folder_hl = "NvimTreeOpenedFolderName"
      end
      if special[node.absolute_path] then
        folder_hl = "NvimTreeSpecialFolderName"
      end
      set_folder_hl(index, offset, #icon + #git_icon, #name, "NvimTreeFolderIcon", folder_hl)
      if git_hl then
        set_folder_hl(index, offset, #icon + #git_icon, #name, git_hl, git_hl)
      end
      index = index + 1
      if node.open then
        table.insert(lines, padding .. icon .. git_icon .. name .. (vim.g.nvim_tree_add_trailing == 1 and "/" or ""))
        update_draw_data(node, depth + 2, markers)
      else
        table.insert(lines, padding .. icon .. git_icon .. name .. (vim.g.nvim_tree_add_trailing == 1 and "/" or ""))
      end
    elseif node.link_to then
      local icon = get_symlink_icon()
      local link_hl = git_hl or "NvimTreeSymlink"
      local arrow = vim.g.nvim_tree_symlink_arrow or " ➛ "
      table.insert(hl, { link_hl, index, offset, -1 })
      table.insert(lines, padding .. icon .. node.name .. arrow .. node.link_to)
      index = index + 1
    else
      local icon
      local git_icons
      if special[node.absolute_path] or special[node.name] then
        icon = get_special_icon()
        git_icons = git.get_icons(node, index, offset, 0, hl)
        table.insert(hl, { "NvimTreeSpecialFile", index, offset + #git_icons, -1 })
      else
        icon = get_file_icon(node.name, node.extension, index, offset)
        git_icons = git.get_icons(node, index, offset, #icon, hl)
      end
      table.insert(lines, padding .. icon .. git_icons .. node.name)

      if node.executable then
        table.insert(hl, { "NvimTreeExecFile", index, offset + #icon + #git_icons, -1 })
      elseif picture[node.extension] then
        table.insert(hl, { "NvimTreeImageFile", index, offset + #icon + #git_icons, -1 })
      end

      if should_hl_opened_files then
        if vim.fn.bufloaded(node.absolute_path) > 0 then
          if vim.g.nvim_tree_highlight_opened_files == 1 then
            table.insert(hl, { "NvimTreeOpenedFile", index, offset, offset + #icon }) -- highlight icon only
          elseif vim.g.nvim_tree_highlight_opened_files == 2 then
            table.insert(hl, {
              "NvimTreeOpenedFile",
              index,
              offset + #icon + #git_icons,
              offset + #icon + #git_icons + #node.name,
            }) -- highlight name only
          elseif vim.g.nvim_tree_highlight_opened_files == 3 then
            table.insert(hl, { "NvimTreeOpenedFile", index, offset, -1 }) -- highlight whole line
          end
        end
      end

      if git_hl then
        table.insert(hl, { git_hl, index, offset + #icon + #git_icons, -1 })
      end
      index = index + 1
    end
  end
end

local M = {}

local function compute_header()
  if view.is_root_folder_visible() then
    local root_folder_modifier = vim.g.nvim_tree_root_folder_modifier or ":~"
    local root_name = utils.path_join {
      utils.path_remove_trailing(vim.fn.fnamemodify(core.get_cwd(), root_folder_modifier)),
      "..",
    }
    table.insert(lines, root_name)
    table.insert(hl, { "NvimTreeRootFolder", index, 0, string.len(root_name) })
    index = 1
  end
end

function M.draw()
  local bufnr = view.get_bufnr()
  if not core.get_explorer() or not bufnr or not api.nvim_buf_is_loaded(bufnr) then
    return
  end
  local cursor
  if view.is_visible() then
    cursor = api.nvim_win_get_cursor(view.get_winnr())
  end
  index = 0
  lines = {}
  hl = {}

  icon_state = _icons.get_config()
  local show_arrows = vim.g.nvim_tree_indent_markers ~= 1
    and icon_state.show_folder_icon
    and icon_state.show_folder_arrows
  _padding.reload_padding_function()
  git.reload()
  compute_header()
  update_draw_data(core.get_explorer(), show_arrows and 2 or 0, {})

  if view.is_help_ui() then
    lines, hl = _help.compute_lines()
  end
  api.nvim_buf_set_option(bufnr, "modifiable", true)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  M.render_hl(bufnr)
  api.nvim_buf_set_option(bufnr, "modifiable", false)

  if cursor and #lines >= cursor[1] then
    api.nvim_win_set_cursor(view.get_winnr(), cursor)
  end
end

function M.render_hl(bufnr)
  if not bufnr or not api.nvim_buf_is_loaded(bufnr) then
    return
  end
  api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  for _, data in ipairs(hl) do
    api.nvim_buf_add_highlight(bufnr, namespace_id, data[1], data[2], data[3], data[4])
  end
end

return M
