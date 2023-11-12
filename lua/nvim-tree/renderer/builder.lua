local utils = require "nvim-tree.utils"
local core = require "nvim-tree.core"
local notify = require "nvim-tree.notify"

local git = require "nvim-tree.renderer.components.git"
local pad = require "nvim-tree.renderer.components.padding"
local icons = require "nvim-tree.renderer.components.icons"
local modified = require "nvim-tree.renderer.components.modified"
local diagnostics = require "nvim-tree.renderer.components.diagnostics"
local bookmarks = require "nvim-tree.renderer.components.bookmarks"

local HL_POSITION = require("nvim-tree.enum").HL_POSITION

local Builder = {}
Builder.__index = Builder

local DEFAULT_ROOT_FOLDER_LABEL = ":~:s?$?/..?"

function Builder.new(root_cwd)
  return setmetatable({
    index = 0,
    depth = 0,
    highlights = {},
    lines = {},
    markers = {},
    signs = {},
    root_cwd = root_cwd,
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

function Builder:configure_opened_file_highlighting(highlight_opened_files)
  self.highlight_opened_files = highlight_opened_files
  return self
end

function Builder:configure_modified_highlighting(highlight_modified)
  self.highlight_modified = highlight_modified
  return self
end

function Builder:configure_icon_padding(padding)
  self.icon_padding = padding or " "
  return self
end

function Builder:configure_git_icons_placement(where)
  if where ~= "after" and where ~= "before" and where ~= "signcolumn" then
    where = "before" -- default before
  end
  self.git_placement = where
  return self
end

function Builder:configure_diagnostics_icon_placement(where)
  if where ~= "after" and where ~= "before" and where ~= "signcolumn" then
    where = "before" -- default before
  end
  self.diagnostics_placement = where
  return self
end

function Builder:configure_bookmark_icon_placement(where)
  if where ~= "after" and where ~= "before" and where ~= "signcolumn" then
    where = "before" -- default before
  end
  self.bookmarks_placement = where
  return self
end

function Builder:configure_modified_placement(where)
  if where ~= "after" and where ~= "before" and where ~= "signcolumn" then
    where = "after" -- default after
  end
  self.modified_placement = where
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

function Builder:_insert_highlight(group, start, end_)
  table.insert(self.highlights, { group, self.index, start, end_ or -1 })
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
    local link_to = utils.path_relative(node.link_to, core.get_cwd())
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
    local link_to = utils.path_relative(node.link_to, core.get_cwd())
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

---@param node table
---@return HighlightedString[]|nil icon
function Builder:_get_git_icons(node)
  local git_icons = git.get_icons(node)
  if git_icons and #git_icons > 0 and self.git_placement == "signcolumn" then
    table.insert(self.signs, {
      sign = git_icons[1].hl[1],
      lnum = self.index + 1,
      priority = 1,
    })
    git_icons = nil
  end
  return git_icons
end

---@param node table
---@return HighlightedString[]|nil icon
function Builder:_get_diagnostics_icon(node)
  local diagnostics_icon = diagnostics.get_icon(node)
  if diagnostics_icon and self.diagnostics_placement == "signcolumn" then
    table.insert(self.signs, {
      sign = diagnostics_icon.hl[1],
      lnum = self.index + 1,
      priority = 2,
    })
    diagnostics_icon = nil
  end
  return diagnostics_icon
end

---@param node table
---@return HighlightedString|nil icon
function Builder:_get_modified_icon(node)
  local modified_icon = modified.get_icon(node)
  if modified_icon and self.modified_placement == "signcolumn" then
    table.insert(self.signs, {
      sign = modified_icon.hl[1],
      lnum = self.index + 1,
      priority = 3,
    })
    modified_icon = nil
  end
  return modified_icon
end

---@param node table
---@return HighlightedString[]|nil icon
function Builder:_get_bookmark_icon(node)
  local bookmark_icon = bookmarks.get_icon(node)
  if bookmark_icon and self.bookmarks_placement == "signcolumn" then
    table.insert(self.signs, {
      sign = bookmark_icon.hl[1],
      lnum = self.index + 1,
      priority = 4,
    })
    bookmark_icon = nil
  end
  return bookmark_icon
end

---@param node table
---@return string|nil icon_hl
---@return string|nil name_hl
function Builder:_get_highlight_override(node, unloaded_bufnr)
  local name_hl, icon_hl

  -- git
  local git_highlight = git.get_highlight(node)
  if git_highlight then
    name_hl = git_highlight
  end

  -- opened file
  if self.highlight_opened_files and vim.fn.bufloaded(node.absolute_path) > 0 and vim.fn.bufnr(node.absolute_path) ~= unloaded_bufnr then
    if self.highlight_opened_files == "all" or self.highlight_opened_files == "name" then
      name_hl = "NvimTreeOpenedFile"
    end
    if self.highlight_opened_files == "all" or self.highlight_opened_files == "icon" then
      icon_hl = "NvimTreeOpenedFileIcon"
    end
  end

  -- modified file
  local modified_highlight = modified.get_highlight(node)
  if modified_highlight then
    if self.highlight_modified == "all" or self.highlight_modified == "name" then
      name_hl = modified_highlight
    end
    if self.highlight_modified == "all" or self.highlight_modified == "icon" then
      icon_hl = modified_highlight
    end
  end

  return icon_hl, name_hl
end

---Append optional highlighting to icon or name.
---@param node table
---@param get_hl fun(node: table): HL_POSITION, string
---@param icon_hl string[] icons to append to
---@param name_hl string[] names to append to
function Builder:_append_highlight(node, get_hl, icon_hl, name_hl)
  local pos, hl = get_hl(node)
  if pos ~= HL_POSITION.none and hl then
    if pos == HL_POSITION.all or pos == HL_POSITION.icon then
      table.insert(icon_hl, hl)
    end
    if pos == HL_POSITION.all or pos == HL_POSITION.name then
      table.insert(name_hl, hl)
    end
  end
end

---@param indent_markers HighlightedString[]
---@param arrows HighlightedString[]|nil
---@param icon HighlightedString
---@param name HighlightedString
---@param git_icons HighlightedString[]|nil
---@param diagnostics_icon HighlightedString|nil
---@param modified_icon HighlightedString|nil
---@param bookmark_icon HighlightedString|nil
---@return HighlightedString[]
function Builder:_format_line(indent_markers, arrows, icon, name, git_icons, diagnostics_icon, modified_icon, bookmark_icon)
  local added_len = 0
  local function add_to_end(t1, t2)
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
  if git_icons and self.git_placement == "before" then
    add_to_end(line, git_icons)
  end
  if modified_icon and self.modified_placement == "before" then
    add_to_end(line, { modified_icon })
  end
  if diagnostics_icon and self.diagnostics_placement == "before" then
    add_to_end(line, { diagnostics_icon })
  end
  if bookmark_icon and self.bookmarks_placement == "before" then
    add_to_end(line, { bookmark_icon })
  end

  add_to_end(line, { name })

  if git_icons and self.git_placement == "after" then
    add_to_end(line, git_icons)
  end
  if modified_icon and self.modified_placement == "after" then
    add_to_end(line, { modified_icon })
  end
  if diagnostics_icon and self.diagnostics_placement == "after" then
    add_to_end(line, { diagnostics_icon })
  end
  if bookmark_icon and self.bookmarks_placement == "after" then
    add_to_end(line, { bookmark_icon })
  end

  return line
end

function Builder:_build_line(node, idx, num_children, unloaded_bufnr)
  local copy_paste = require "nvim-tree.actions.fs.copy-paste"

  -- various components
  local indent_markers = pad.get_indent_markers(self.depth, idx, num_children, node, self.markers)
  local arrows = pad.get_arrows(node)

  -- adds icons to signcolumn
  local bookmark_icon = self:_get_bookmark_icon(node)
  local git_icons = self:_get_git_icons(node)
  local modified_icon = self:_get_modified_icon(node)
  local diagnostics_icon = self:_get_diagnostics_icon(node)

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

  -- highlight override
  local icon_hl_override, name_hl_override = self:_get_highlight_override(node, unloaded_bufnr)
  if icon_hl_override then
    icon.hl = { icon_hl_override }
  end
  if name_hl_override then
    name.hl = { name_hl_override }
  end

  -- extra highighting
  self:_append_highlight(node, bookmarks.get_highlight, icon.hl, name.hl)
  self:_append_highlight(node, diagnostics.get_highlight, icon.hl, name.hl)
  self:_append_highlight(node, copy_paste.get_highlight, icon.hl, name.hl)

  local line = self:_format_line(indent_markers, arrows, icon, name, git_icons, diagnostics_icon, modified_icon, bookmark_icon)
  self:_insert_line(self:_unwrap_highlighted_strings(line))

  self.index = self.index + 1

  node = require("nvim-tree.lib").get_last_group_node(node)

  if node.open then
    self.depth = self.depth + 1
    self:build(node, unloaded_bufnr)
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

function Builder:build(tree, unloaded_bufnr)
  local num_children = self:_get_nodes_number(tree.nodes)
  local idx = 1
  for _, node in ipairs(tree.nodes) do
    if not node.hidden then
      self:_build_line(node, idx, num_children, unloaded_bufnr)
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
  return self.lines, self.highlights, self.signs
end

return Builder
