local core = require "nvim-tree.core"
local notify = require "nvim-tree.notify"
local utils = require "nvim-tree.utils"
local view = require "nvim-tree.view"

local DecoratorBookmarks = require "nvim-tree.renderer.decorator.bookmarks"
local DecoratorCopied = require "nvim-tree.renderer.decorator.copied"
local DecoratorCut = require "nvim-tree.renderer.decorator.cut"
local DecoratorDiagnostics = require "nvim-tree.renderer.decorator.diagnostics"
local DecoratorGit = require "nvim-tree.renderer.decorator.git"
local DecoratorModified = require "nvim-tree.renderer.decorator.modified"
local DecoratorHidden = require "nvim-tree.renderer.decorator.hidden"
local DecoratorOpened = require "nvim-tree.renderer.decorator.opened"

local pad = require "nvim-tree.renderer.components.padding"
local icons = require "nvim-tree.renderer.components.icons"

local M = {
  opts = {},
  decorators = {},
  picture_map = {
    jpg = true,
    jpeg = true,
    png = true,
    gif = true,
    webp = true,
    jxl = true,
  },
}

---@class HighlightedString
---@field str string
---@field hl string[]

---@class AddHighlightArgs
---@field group string[]
---@field line number
---@field col_start number
---@field col_end number

---@class Builder
---@field lines string[] includes icons etc.
---@field hl_args AddHighlightArgs[] line highlights
---@field signs string[] line signs
---@field extmarks table[] extra marks for right icon placement
---@field virtual_lines table[] virtual lines for hidden count display
---@field private root_cwd string absolute path
---@field private index number
---@field private depth number
---@field private combined_groups table<string, boolean> combined group names
---@field private markers boolean[] indent markers
local Builder = {}

---@return Builder
function Builder:new()
  local o = {
    root_cwd = core.get_cwd(),
    index = 0,
    depth = 0,
    hl_args = {},
    combined_groups = {},
    lines = {},
    markers = {},
    signs = {},
    extmarks = {},
    virtual_lines = {},
  }
  setmetatable(o, self)
  self.__index = self

  return o
end

---Insert ranged highlight groups into self.highlights
---@private
---@param groups string[]
---@param start number
---@param end_ number|nil
function Builder:insert_highlight(groups, start, end_)
  table.insert(self.hl_args, { groups, self.index, start, end_ or -1 })
end

---@private
function Builder:get_folder_name(node)
  local name = node.name
  local next = node.group_next
  while next do
    name = string.format("%s/%s", name, next.name)
    next = next.group_next
  end

  if node.group_next and type(M.opts.renderer.group_empty) == "function" then
    local new_name = M.opts.renderer.group_empty(name)
    if type(new_name) == "string" then
      name = new_name
    else
      notify.warn(string.format("Invalid return type for field renderer.group_empty. Expected string, got %s", type(new_name)))
    end
  end

  return string.format("%s%s", name, M.opts.renderer.add_trailing and "/" or "")
end

---@private
---@param highlighted_strings HighlightedString[]
---@return string
function Builder:unwrap_highlighted_strings(highlighted_strings)
  if not highlighted_strings then
    return ""
  end

  local string = ""
  for _, v in ipairs(highlighted_strings) do
    if #v.str > 0 then
      if v.hl and type(v.hl) == "table" then
        self:insert_highlight(v.hl, #string, #string + #v.str)
      end
      string = string.format("%s%s", string, v.str)
    end
  end
  return string
end

---@private
---@param node table
---@return HighlightedString icon
---@return HighlightedString name
function Builder:build_folder(node)
  local has_children = #node.nodes ~= 0 or node.has_children
  local icon, icon_hl = icons.get_folder_icon(node, has_children)
  local foldername = self:get_folder_name(node)

  if #icon > 0 and icon_hl == nil then
    if node.open then
      icon_hl = "NvimTreeOpenedFolderIcon"
    else
      icon_hl = "NvimTreeClosedFolderIcon"
    end
  end

  local foldername_hl = "NvimTreeFolderName"
  if node.link_to and M.opts.renderer.symlink_destination then
    local arrow = icons.i.symlink_arrow
    local link_to = utils.path_relative(node.link_to, self.root_cwd)
    foldername = string.format("%s%s%s", foldername, arrow, link_to)
    foldername_hl = "NvimTreeSymlinkFolderName"
  elseif
    vim.tbl_contains(M.opts.renderer.special_files, node.absolute_path) or vim.tbl_contains(M.opts.renderer.special_files, node.name)
  then
    foldername_hl = "NvimTreeSpecialFolderName"
  elseif node.open then
    foldername_hl = "NvimTreeOpenedFolderName"
  elseif not has_children then
    foldername_hl = "NvimTreeEmptyFolderName"
  end

  return { str = icon, hl = { icon_hl } }, { str = foldername, hl = { foldername_hl } }
end

---@private
---@param node table
---@return HighlightedString icon
---@return HighlightedString name
function Builder:build_symlink(node)
  local icon = icons.i.symlink
  local arrow = icons.i.symlink_arrow
  local symlink_formatted = node.name
  if M.opts.renderer.symlink_destination then
    local link_to = utils.path_relative(node.link_to, self.root_cwd)
    symlink_formatted = string.format("%s%s%s", symlink_formatted, arrow, link_to)
  end

  return { str = icon, hl = { "NvimTreeSymlinkIcon" } }, { str = symlink_formatted, hl = { "NvimTreeSymlink" } }
end

---@private
---@param node table
---@return HighlightedString icon
---@return HighlightedString name
function Builder:build_file(node)
  local hl
  if vim.tbl_contains(M.opts.renderer.special_files, node.absolute_path) or vim.tbl_contains(M.opts.renderer.special_files, node.name) then
    hl = "NvimTreeSpecialFile"
  elseif node.executable then
    hl = "NvimTreeExecFile"
  elseif M.picture_map[node.extension] then
    hl = "NvimTreeImageFile"
  end

  local icon, hl_group = icons.get_file_icon(node.name, node.extension)
  return { str = icon, hl = { hl_group } }, { str = node.name, hl = { hl } }
end

---@private
---@param indent_markers HighlightedString[]
---@param arrows HighlightedString[]|nil
---@param icon HighlightedString
---@param name HighlightedString
---@param node table
---@return HighlightedString[]
function Builder:format_line(indent_markers, arrows, icon, name, node)
  local added_len = 0
  local function add_to_end(t1, t2)
    if not t2 then
      return
    end
    for _, v in ipairs(t2) do
      if added_len > 0 then
        table.insert(t1, { str = M.opts.renderer.icons.padding })
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

  for i = #M.decorators, 1, -1 do
    add_to_end(line, M.decorators[i]:icons_before(node))
  end

  add_to_end(line, { name })

  for i = #M.decorators, 1, -1 do
    add_to_end(line, M.decorators[i]:icons_after(node))
  end

  local rights = {}
  for i = #M.decorators, 1, -1 do
    add_to_end(rights, M.decorators[i]:icons_right_align(node))
  end
  if #rights > 0 then
    self.extmarks[self.index] = rights
  end

  return line
end

---@private
---@param node Node
function Builder:build_signs(node)
  -- first in priority order
  local sign_name
  for _, d in ipairs(M.decorators) do
    sign_name = d:sign_name(node)
    if sign_name then
      self.signs[self.index] = sign_name
      break
    end
  end
end

---Create a highlight group for groups with later groups overriding previous.
---Combined group name is less than the 200 byte limit of highlight group names
---@private
---@param groups string[] highlight group names
---@return string group_name "NvimTreeCombinedHL" .. sha256
function Builder:create_combined_group(groups)
  local combined_name = string.format("NvimTreeCombinedHL%s", vim.fn.sha256(table.concat(groups)))

  -- only create if necessary
  if not self.combined_groups[combined_name] then
    self.combined_groups[combined_name] = true
    local combined_hl = {}

    -- build the highlight, overriding values
    for _, group in ipairs(groups) do
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      combined_hl = vim.tbl_extend("force", combined_hl, hl)
    end

    -- add highlights to the global namespace
    vim.api.nvim_set_hl(0, combined_name, combined_hl)

    table.insert(self.combined_groups, combined_name)
  end

  return combined_name
end

---Calculate highlight group for icon and name. A combined highlight group will be created
---when there is more than one highlight.
---A highlight group is always calculated and upserted for the case of highlights changing.
---@private
---@param node Node
---@return string|nil icon_hl_group
---@return string|nil name_hl_group
function Builder:add_highlights(node)
  -- result
  local icon_hl_group, name_hl_group

  -- calculate all groups
  local icon_groups = {}
  local name_groups = {}
  local d, icon, name
  for i = #M.decorators, 1, -1 do
    d = M.decorators[i]
    icon, name = d:groups_icon_name(node)
    table.insert(icon_groups, icon)
    table.insert(name_groups, name)
  end

  -- one or many icon groups
  if #icon_groups > 1 then
    icon_hl_group = self:create_combined_group(icon_groups)
  else
    icon_hl_group = icon_groups[1]
  end

  -- one or many name groups
  if #name_groups > 1 then
    name_hl_group = self:create_combined_group(name_groups)
  else
    name_hl_group = name_groups[1]
  end

  return icon_hl_group, name_hl_group
end

---@private
function Builder:build_line(node, idx, num_children)
  -- various components
  local indent_markers = pad.get_indent_markers(self.depth, idx, num_children, node, self.markers)
  local arrows = pad.get_arrows(node)

  -- main components
  local is_folder = node.nodes ~= nil
  local is_symlink = node.link_to ~= nil
  local icon, name
  if is_folder then
    icon, name = self:build_folder(node)
  elseif is_symlink then
    icon, name = self:build_symlink(node)
  else
    icon, name = self:build_file(node)
  end

  -- highighting
  local icon_hl_group, name_hl_group = self:add_highlights(node)
  table.insert(icon.hl, icon_hl_group)
  table.insert(name.hl, name_hl_group)

  local line = self:format_line(indent_markers, arrows, icon, name, node)
  table.insert(self.lines, self:unwrap_highlighted_strings(line))

  self.index = self.index + 1

  node = require("nvim-tree.lib").get_last_group_node(node)
  if node.open then
    self.depth = self.depth + 1
    self:build_lines(node)
    self.depth = self.depth - 1
  end
end

---Add virtual lines for rendering hidden count information per node
---@private
function Builder:add_hidden_count_string(node, idx, num_children)
  if not node.open then
    return
  end
  local hidden_count_string = M.opts.renderer.hidden_display(node.hidden_stats)
  if hidden_count_string and hidden_count_string ~= "" then
    local indent_markers = pad.get_indent_markers(self.depth, idx or 0, num_children or 0, node, self.markers, 1)
    local indent_width = M.opts.renderer.indent_width

    local indent_padding = string.rep(" ", indent_width)
    local indent_string = indent_padding .. indent_markers.str
    local line_nr = #self.lines - 1
    self.virtual_lines[line_nr] = self.virtual_lines[line_nr] or {}

    -- NOTE: We are inserting in depth order because of current traversal
    -- if we change the traversal, we might need to sort by depth before rendering `self.virtual_lines`
    -- to maintain proper ordering of parent and child folder hidden count info.
    table.insert(self.virtual_lines[line_nr], {
      { indent_string, indent_markers.hl },
      { string.rep(indent_padding, (node.parent == nil and 0 or 1)) .. hidden_count_string, "NvimTreeHiddenDisplay" },
    })
  end
end

---@private
function Builder:get_nodes_number(nodes)
  local explorer = core.get_explorer()
  if not explorer or not explorer.live_filter.filter then
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

---@private
function Builder:build_lines(node)
  if not node then
    node = core.get_explorer()
  end
  local num_children = self:get_nodes_number(node.nodes)
  local idx = 1
  for _, n in ipairs(node.nodes) do
    if not n.hidden then
      self:build_signs(n)
      self:build_line(n, idx, num_children)
      idx = idx + 1
    end
  end
  self:add_hidden_count_string(node)
end

---@private
---@param root_label function|string
---@return string
function Builder:format_root_name(root_label)
  if type(root_label) == "function" then
    local label = root_label(self.root_cwd)
    if type(label) == "string" then
      return label
    end
  elseif type(root_label) == "string" then
    return utils.path_remove_trailing(vim.fn.fnamemodify(self.root_cwd, root_label))
  end
  return "???"
end

---@private
function Builder:build_header()
  local explorer = core.get_explorer()
  if view.is_root_folder_visible(core.get_cwd()) then
    local root_name = self:format_root_name(M.opts.renderer.root_folder_label)
    table.insert(self.lines, root_name)
    self:insert_highlight({ "NvimTreeRootFolder" }, 0, string.len(root_name))
    self.index = 1
  end

  if explorer and explorer.live_filter.filter then
    local filter_line = string.format("%s/%s/", M.opts.live_filter.prefix, explorer.live_filter.filter)
    table.insert(self.lines, filter_line)
    local prefix_length = string.len(M.opts.live_filter.prefix)
    self:insert_highlight({ "NvimTreeLiveFilterPrefix" }, 0, prefix_length)
    self:insert_highlight({ "NvimTreeLiveFilterValue" }, prefix_length, string.len(filter_line))
    self.index = self.index + 1
  end
end

---Sanitize lines for rendering.
---Replace newlines with literal \n
---@private
function Builder:sanitize_lines()
  self.lines = vim.tbl_map(function(line)
    return line and line:gsub("\n", "\\n") or ""
  end, self.lines)
end

---Build all lines with highlights and signs
---@return Builder
function Builder:build()
  self:build_header()
  self:build_lines()
  self:sanitize_lines()
  return self
end

---@param opts table
local setup_hidden_display_function = function(opts)
  local hidden_display = opts.renderer.hidden_display
  -- options are already validated, so ´hidden_display´ can ONLY be `string` or `function` if type(hidden_display) == "string" then
  if type(hidden_display) == "string" then
    if hidden_display == "none" then
      opts.renderer.hidden_display = function()
        return nil
      end
    elseif hidden_display == "simple" then
      opts.renderer.hidden_display = function(hidden_stats)
        return utils.default_format_hidden_count(hidden_stats, true)
      end
    elseif hidden_display == "all" then
      opts.renderer.hidden_display = function(hidden_stats)
        return utils.default_format_hidden_count(hidden_stats, false)
      end
    end
  elseif type(hidden_display) == "function" then
    local safe_render = function(hidden_stats)
      -- In case of missing field such as live_filter we zero it, otherwise keep field as is
      hidden_stats = vim.tbl_deep_extend("force", {
        live_filter = 0,
        git = 0,
        buf = 0,
        dotfile = 0,
        custom = 0,
        bookmark = 0,
      }, hidden_stats or {})

      local ok, result = pcall(hidden_display, hidden_stats)
      if not ok then
        notify.warn "Problem occurred in the function ``opts.renderer.hidden_display`` see nvim-tree.renderer.hidden_display on :h nvim-tree"
        return nil
      end
      return result
    end

    opts.renderer.hidden_display = safe_render
  end
end

function Builder.setup(opts)
  setup_hidden_display_function(opts)
  M.opts = opts

  -- priority order
  M.decorators = {
    DecoratorCut:new(opts),
    DecoratorCopied:new(opts),
    DecoratorDiagnostics:new(opts),
    DecoratorBookmarks:new(opts),
    DecoratorModified:new(opts),
    DecoratorHidden:new(opts),
    DecoratorOpened:new(opts),
    DecoratorGit:new(opts),
  }
end

return Builder
