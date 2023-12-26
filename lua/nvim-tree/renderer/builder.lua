local utils = require "nvim-tree.utils"
local notify = require "nvim-tree.notify"

local pad = require "nvim-tree.renderer.components.padding"
local icons = require "nvim-tree.renderer.components.icons"

---@class Builder
---@field private index number
---@field private depth number
---@field private highlights table[] hl_group, line, col_start, col_end arguments for vim.api.nvim_buf_add_highlight
---@field private combined_groups boolean[] combined group names
---@field private lines string[] includes icons etc.
---@field private markers boolean[] indent markers
---@field private sign_names string[] line signs
---@field private root_cwd string absolute path
---@field private decorators Decorator[] in priority order
local Builder = {}
Builder.__index = Builder

local DEFAULT_ROOT_FOLDER_LABEL = ":~:s?$?/..?"

function Builder.new(root_cwd, decorators)
  return setmetatable({
    index = 0,
    depth = 0,
    highlights = {},
    combined_groups = {},
    lines = {},
    markers = {},
    sign_names = {},
    root_cwd = root_cwd,
    decorators = decorators,
  }, Builder)
end

function Builder:configure_root_label(root_folder_label)
  self.root_folder_label = root_folder_label or DEFAULT_ROOT_FOLDER_LABEL
  return self
end

function Builder:configure_trailing_slash(with_trailing)
  self.trailing_slash = with_trailing and "/" or ""
  return self
end

function Builder:configure_special_files(special_files)
  self.special_files = special_files
  return self
end

function Builder:configure_picture_map(picture_map)
  self.picture_map = picture_map
  return self
end

function Builder:configure_filter(filter, prefix)
  self.filter_prefix = prefix
  self.filter = filter
  return self
end

function Builder:configure_icon_padding(padding)
  self.icon_padding = padding or " "
  return self
end

function Builder:configure_symlink_destination(show)
  self.symlink_destination = show
  return self
end

function Builder:configure_group_name_modifier(group_name_modifier)
  if type(group_name_modifier) == "function" then
    self.group_name_modifier = group_name_modifier
  end
  return self
end

---Insert ranged highlight groups into self.highlights
---@param groups string[]
---@param start number
---@param end_ number|nil
function Builder:_insert_highlight(groups, start, end_)
  table.insert(self.highlights, { groups, self.index, start, end_ or -1 })
end

function Builder:_insert_line(line)
  table.insert(self.lines, line)
end

function Builder:_get_folder_name(node)
  local name = node.name
  local next = node.group_next
  while next do
    name = name .. "/" .. next.name
    next = next.group_next
  end

  if node.group_next and self.group_name_modifier then
    local new_name = self.group_name_modifier(name)
    if type(new_name) == "string" then
      name = new_name
    else
      notify.warn(string.format("Invalid return type for field renderer.group_empty. Expected string, got %s", type(new_name)))
    end
  end

  return name .. self.trailing_slash
end

---@class HighlightedString
---@field str string
---@field hl string[]

---@param highlighted_strings HighlightedString[]
---@return string
function Builder:_unwrap_highlighted_strings(highlighted_strings)
  if not highlighted_strings then
    return ""
  end

  local string = ""
  for _, v in ipairs(highlighted_strings) do
    if #v.str > 0 then
      if v.hl and type(v.hl) == "table" then
        self:_insert_highlight(v.hl, #string, #string + #v.str)
      end
      string = string .. v.str
    end
  end
  return string
end

---@param node table
---@return HighlightedString icon
---@return HighlightedString name
function Builder:_build_folder(node)
  local has_children = #node.nodes ~= 0 or node.has_children
  local icon, icon_hl = icons.get_folder_icon(node, has_children)
  local foldername = self:_get_folder_name(node)

  if #icon > 0 and icon_hl == nil then
    if node.open then
      icon_hl = "NvimTreeOpenedFolderIcon"
    else
      icon_hl = "NvimTreeClosedFolderIcon"
    end
  end

  local foldername_hl = "NvimTreeFolderName"
  if node.link_to and self.symlink_destination then
    local arrow = icons.i.symlink_arrow
    local link_to = utils.path_relative(node.link_to, self.root_cwd)
    foldername = foldername .. arrow .. link_to
    foldername_hl = "NvimTreeSymlinkFolderName"
  elseif vim.tbl_contains(self.special_files, node.absolute_path) or vim.tbl_contains(self.special_files, node.name) then
    foldername_hl = "NvimTreeSpecialFolderName"
  elseif node.open then
    foldername_hl = "NvimTreeOpenedFolderName"
  elseif not has_children then
    foldername_hl = "NvimTreeEmptyFolderName"
  end

  return { str = icon, hl = { icon_hl } }, { str = foldername, hl = { foldername_hl } }
end

---@param node table
---@return HighlightedString icon
---@return HighlightedString name
function Builder:_build_symlink(node)
  local icon = icons.i.symlink
  local arrow = icons.i.symlink_arrow
  local symlink_formatted = node.name
  if self.symlink_destination then
    local link_to = utils.path_relative(node.link_to, self.root_cwd)
    symlink_formatted = symlink_formatted .. arrow .. link_to
  end

  return { str = icon, hl = { "NvimTreeSymlinkIcon" } }, { str = symlink_formatted, hl = { "NvimTreeSymlink" } }
end

---@param node table
---@return HighlightedString icon
function Builder:_build_file_icon(node)
  local icon, hl_group = icons.get_file_icon(node.name, node.extension)
  return { str = icon, hl = { hl_group } }
end

---@param node table
---@return HighlightedString icon
---@return HighlightedString name
function Builder:_build_file(node)
  local icon = self:_build_file_icon(node)

  local hl
  if vim.tbl_contains(self.special_files, node.absolute_path) or vim.tbl_contains(self.special_files, node.name) then
    hl = "NvimTreeSpecialFile"
  elseif node.executable then
    hl = "NvimTreeExecFile"
  elseif self.picture_map[node.extension] then
    hl = "NvimTreeImageFile"
  end

  return icon, { str = node.name, hl = { hl } }
end

---@param indent_markers HighlightedString[]
---@param arrows HighlightedString[]|nil
---@param icon HighlightedString
---@param name HighlightedString
---@param node table
---@return HighlightedString[]
function Builder:_format_line(indent_markers, arrows, icon, name, node)
  local added_len = 0
  local function add_to_end(t1, t2)
    if not t2 then
      return
    end
    for _, v in ipairs(t2) do
      if added_len > 0 then
        table.insert(t1, { str = self.icon_padding })
      end
      table.insert(t1, v)
    end

    -- first add_to_end don't need padding
    -- hence added_len is calculated at the end to be used next time
    added_len = 0
    for _, v in ipairs(t2) do
      added_len = added_len + #v.str
    end
  end

  local line = { indent_markers, arrows }
  add_to_end(line, { icon })

  for i = #self.decorators, 1, -1 do
    add_to_end(line, self.decorators[i]:icons_before(node))
  end

  add_to_end(line, { name })

  for i = #self.decorators, 1, -1 do
    add_to_end(line, self.decorators[i]:icons_after(node))
  end

  return line
end

function Builder:_build_signs(node)
  -- first in priority order
  local sign_name
  for _, d in ipairs(self.decorators) do
    sign_name = d:sign_name(node)
    if sign_name then
      self.sign_names[self.index] = sign_name
      break
    end
  end
end

---Combined group name less than the 200 byte limit of highlight group names
---@param groups string[] highlight group names
---@return string name "NvimTreeCombinedHL" .. sha256
function Builder:_combined_group_name(groups)
  return string.format("NvimTreeCombinedHL%s", vim.fn.sha256(table.concat(groups)))
end

---Create a highlight group for groups with later groups overriding previous.
---@param groups string[] highlight group names
function Builder:_create_combined_group(groups)
  local combined_name = self:_combined_group_name(groups)

  -- only create if necessary
  if not self.combined_groups[combined_name] then
    local combined_hl = {}

    -- build the highlight, overriding values
    for _, group in ipairs(groups) do
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      combined_hl = vim.tbl_extend("force", combined_hl, hl)
    end

    -- create and note the name
    vim.api.nvim_set_hl(0, combined_name, combined_hl)
    self.combined_groups[combined_name] = true
  end
end

---Calculate highlight group for icon and name. A combined highlight group will be created
---when there is more than one highlight.
---A highlight group is always calculated and upserted for the case of highlights changing.
---@param node Node
---@return string|nil icon_hl_group
---@return string|nil name_hl_group
function Builder:_add_highlights(node)
  -- result
  local icon_hl_group, name_hl_group

  -- calculate all groups
  local icon_groups = {}
  local name_groups = {}
  local d, icon, name
  for i = #self.decorators, 1, -1 do
    d = self.decorators[i]
    icon, name = d:groups_icon_name(node)
    table.insert(icon_groups, icon)
    table.insert(name_groups, name)
  end

  -- one or many icon groups
  if #icon_groups > 1 then
    icon_hl_group = self:_combined_group_name(icon_groups)
    self:_create_combined_group(icon_groups)
  else
    icon_hl_group = icon_groups[1]
  end

  -- one or many name groups
  if #name_groups > 1 then
    name_hl_group = self:_combined_group_name(name_groups)
    self:_create_combined_group(name_groups)
  else
    name_hl_group = name_groups[1]
  end

  return icon_hl_group, name_hl_group
end

function Builder:_build_line(node, idx, num_children)
  -- various components
  local indent_markers = pad.get_indent_markers(self.depth, idx, num_children, node, self.markers)
  local arrows = pad.get_arrows(node)

  -- main components
  local is_folder = node.nodes ~= nil
  local is_symlink = node.link_to ~= nil
  local icon, name
  if is_folder then
    icon, name = self:_build_folder(node)
  elseif is_symlink then
    icon, name = self:_build_symlink(node)
  else
    icon, name = self:_build_file(node)
  end

  -- highighting
  local icon_hl_group, name_hl_group = self:_add_highlights(node)
  table.insert(icon.hl, icon_hl_group)
  table.insert(name.hl, name_hl_group)

  local line = self:_format_line(indent_markers, arrows, icon, name, node)
  self:_insert_line(self:_unwrap_highlighted_strings(line))

  self.index = self.index + 1

  node = require("nvim-tree.lib").get_last_group_node(node)

  if node.open then
    self.depth = self.depth + 1
    self:build(node)
    self.depth = self.depth - 1
  end
end

function Builder:_get_nodes_number(nodes)
  if not self.filter then
    return #nodes
  end

  local i = 0
  for _, n in pairs(nodes) do
    if not n.hidden then
      i = i + 1
    end
  end
  return i
end

function Builder:build(tree)
  local num_children = self:_get_nodes_number(tree.nodes)
  local idx = 1
  for _, node in ipairs(tree.nodes) do
    if not node.hidden then
      self:_build_signs(node)
      self:_build_line(node, idx, num_children)
      idx = idx + 1
    end
  end

  return self
end

local function format_root_name(root_cwd, root_label)
  if type(root_label) == "function" then
    local label = root_label(root_cwd)
    if type(label) == "string" then
      return label
    else
      root_label = DEFAULT_ROOT_FOLDER_LABEL
    end
  end
  return utils.path_remove_trailing(vim.fn.fnamemodify(root_cwd, root_label))
end

function Builder:build_header(show_header)
  if show_header then
    local root_name = format_root_name(self.root_cwd, self.root_folder_label)
    self:_insert_line(root_name)
    self:_insert_highlight({ "NvimTreeRootFolder" }, 0, string.len(root_name))
    self.index = 1
  end

  if self.filter then
    local filter_line = self.filter_prefix .. "/" .. self.filter .. "/"
    self:_insert_line(filter_line)
    local prefix_length = string.len(self.filter_prefix)
    self:_insert_highlight({ "NvimTreeLiveFilterPrefix" }, 0, prefix_length)
    self:_insert_highlight({ "NvimTreeLiveFilterValue" }, prefix_length, string.len(filter_line))
    self.index = self.index + 1
  end

  return self
end

function Builder:unwrap()
  return self.lines, self.highlights, self.sign_names
end

return Builder
