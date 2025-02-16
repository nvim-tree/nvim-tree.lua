local notify = require("nvim-tree.notify")
local utils = require("nvim-tree.utils")
local view = require("nvim-tree.view")

local Class = require("nvim-tree.classic")

local DirectoryNode = require("nvim-tree.node.directory")

local BookmarkDecorator = require("nvim-tree.renderer.decorator.bookmarks")
local CopiedDecorator = require("nvim-tree.renderer.decorator.copied")
local CutDecorator = require("nvim-tree.renderer.decorator.cut")
local DiagnosticsDecorator = require("nvim-tree.renderer.decorator.diagnostics")
local GitDecorator = require("nvim-tree.renderer.decorator.git")
local HiddenDecorator = require("nvim-tree.renderer.decorator.hidden")
local ModifiedDecorator = require("nvim-tree.renderer.decorator.modified")
local OpenDecorator = require("nvim-tree.renderer.decorator.opened")
local UserDecorator = require("nvim-tree.renderer.decorator.user")

local pad = require("nvim-tree.renderer.components.padding")

---@alias HighlightedString nvim_tree.api.HighlightedString

-- Builtin Decorators
---@type table<nvim_tree.api.decorator.Name, Decorator>
local BUILTIN_DECORATORS = {
  Git = GitDecorator,
  Open = OpenDecorator,
  Hidden = HiddenDecorator,
  Modified = ModifiedDecorator,
  Bookmark = BookmarkDecorator,
  Diagnostics = DiagnosticsDecorator,
  Copied = CopiedDecorator,
  Cut = CutDecorator,
}

---@class (exact) Builder
---@field lines string[] includes icons etc.
---@field hl_range_args HighlightRangeArgs[] highlights for lines
---@field signs string[] line signs
---@field extmarks table[] extra marks for right icon placement
---@field virtual_lines table[] virtual lines for hidden count display
---@field private explorer Explorer
---@field private index number
---@field private depth number
---@field private combined_groups table<string, boolean> combined group names
---@field private markers boolean[] indent markers
---@field private decorators Decorator[]
---@field private hidden_display fun(node: Node): string|nil
---@field private api_nodes table<number, nvim_tree.api.Node>? optional map of uids to api node for user decorators
local Builder = Class:extend()

---@class Builder
---@overload fun(args: BuilderArgs): Builder

---@class (exact) BuilderArgs
---@field explorer Explorer

---@protected
---@param args BuilderArgs
function Builder:new(args)
  self.explorer        = args.explorer
  self.index           = 0
  self.depth           = 0
  self.hl_range_args   = {}
  self.combined_groups = {}
  self.lines           = {}
  self.markers         = {}
  self.signs           = {}
  self.extmarks        = {}
  self.virtual_lines   = {}
  self.decorators      = {}
  self.hidden_display  = Builder:setup_hidden_display_function(self.explorer.opts)

  -- instantiate all the builtin and user decorator instances
  local builtin, user
  for _, d in ipairs(self.explorer.opts.renderer.decorators) do
    ---@type Decorator
    builtin = BUILTIN_DECORATORS[d]

    ---@type UserDecorator
    user = type(d) == "table" and type(d.as) == "function" and d:as(UserDecorator)

    if builtin then
      table.insert(self.decorators, builtin({ explorer = self.explorer }))
    elseif user then
      table.insert(self.decorators, user())

      -- clone user nodes once
      if not self.api_nodes then
        self.api_nodes = {}
        self.explorer:clone(self.api_nodes)
      end
    end
  end
end

---Insert ranged highlight groups into self.highlights
---@private
---@param groups string[]
---@param start number
---@param end_ number|nil
function Builder:insert_highlight(groups, start, end_)
  for _, higroup in ipairs(groups) do
    table.insert(self.hl_range_args, { higroup = higroup, start = { self.index, start, }, finish = { self.index, end_ or -1, } })
  end
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
        table.insert(t1, { str = self.explorer.opts.renderer.icons.padding })
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

  -- use the api node for user decorators
  local api_node = self.api_nodes and self.api_nodes[node.uid_node] --[[@as Node]]

  local line = { indent_markers, arrows }
  add_to_end(line, { icon })

  for _, d in ipairs(self.decorators) do
    add_to_end(line, d:icons_before(not d:is(UserDecorator) and node or api_node))
  end

  add_to_end(line, { name })

  for _, d in ipairs(self.decorators) do
    add_to_end(line, d:icons_after(not d:is(UserDecorator) and node or api_node))
  end

  local rights = {}
  for _, d in ipairs(self.decorators) do
    add_to_end(rights, d:icons_right_align(not d:is(UserDecorator) and node or api_node))
  end
  if #rights > 0 then
    self.extmarks[self.index] = rights
  end

  return line
end

---@private
---@param node Node
function Builder:build_signs(node)
  -- use the api node for user decorators
  local api_node = self.api_nodes and self.api_nodes[node.uid_node] --[[@as Node]]

  -- first in priority order
  local d, sign_name
  for i = #self.decorators, 1, -1 do
    d = self.decorators[i]
    sign_name = d:sign_name(not d:is(UserDecorator) and node or api_node)
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

---Calculate decorated icon and name for a node.
---A combined highlight group will be created when there is more than one highlight.
---A highlight group is always calculated and upserted for the case of highlights changing.
---@private
---@param node Node
---@return HighlightedString icon
---@return HighlightedString name
function Builder:icon_name_decorated(node)
  -- use the api node for user decorators
  local api_node = self.api_nodes and self.api_nodes[node.uid_node] --[[@as Node]]

  -- base case
  local icon = node:highlighted_icon()
  local name = node:highlighted_name()

  -- calculate node icon and all decorated highlight groups
  local icon_groups = {}
  local name_groups = {}
  local hl_icon, hl_name
  for _, d in ipairs(self.decorators) do
    -- maybe overridde icon
    icon = d:icon_node((not d:is(UserDecorator) and node or api_node)) or icon

    hl_icon, hl_name = d:highlight_group_icon_name((not d:is(UserDecorator) and node or api_node))

    table.insert(icon_groups, hl_icon)
    table.insert(name_groups, hl_name)
  end

  -- add one or many icon groups
  if #icon_groups > 1 then
    table.insert(icon.hl, self:create_combined_group(icon_groups))
  else
    table.insert(icon.hl, icon_groups[1])
  end

  -- add one or many name groups
  if #name_groups > 1 then
    table.insert(name.hl, self:create_combined_group(name_groups))
  else
    table.insert(name.hl, name_groups[1])
  end

  return icon, name
end

---Insert node line into self.lines, calling Builder:build_lines for each directory
---@private
---@param node Node
---@param idx integer line number starting at 1
---@param num_children integer of node
function Builder:build_line(node, idx, num_children)
  -- various components
  local indent_markers = pad.get_indent_markers(self.depth, idx, num_children, node, self.markers)
  local arrows = pad.get_arrows(node)

  -- decorated node icon and name
  local icon, name = self:icon_name_decorated(node)

  local line = self:format_line(indent_markers, arrows, icon, name, node)
  table.insert(self.lines, self:unwrap_highlighted_strings(line))

  self.index = self.index + 1

  local dir = node:as(DirectoryNode)
  if dir then
    dir = dir:last_group_node()
    if dir.open then
      self.depth = self.depth + 1
      self:build_lines(dir)
      self.depth = self.depth - 1
    end
  end
end

---Add virtual lines for rendering hidden count information per node
---@private
function Builder:add_hidden_count_string(node, idx, num_children)
  if not node.open then
    return
  end
  local hidden_count_string = self.hidden_display(node.hidden_stats)
  if hidden_count_string and hidden_count_string ~= "" then
    local indent_markers = pad.get_indent_markers(self.depth, idx or 0, num_children or 0, node, self.markers, 1)
    local indent_width = self.explorer.opts.renderer.indent_width

    local indent_padding = string.rep(" ", indent_width)
    local indent_string = indent_padding .. indent_markers.str
    local line_nr = #self.lines - 1
    self.virtual_lines[line_nr] = self.virtual_lines[line_nr] or {}

    -- NOTE: We are inserting in depth order because of current traversal
    -- if we change the traversal, we might need to sort by depth before rendering `self.virtual_lines`
    -- to maintain proper ordering of parent and child folder hidden count info.
    table.insert(self.virtual_lines[line_nr], {
      { indent_string,                                                                      indent_markers.hl },
      { string.rep(indent_padding, (node.parent == nil and 0 or 1)) .. hidden_count_string, "NvimTreeHiddenDisplay" },
    })
  end
end

---Number of visible nodes
---@private
---@param nodes Node[]
---@return integer
function Builder:num_visible(nodes)
  if not self.explorer.live_filter.filter then
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
    node = self.explorer
  end
  local num_children = self:num_visible(node.nodes)
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
    local label = root_label(self.explorer.absolute_path)
    if type(label) == "string" then
      return label
    end
  elseif type(root_label) == "string" then
    return utils.path_remove_trailing(vim.fn.fnamemodify(self.explorer.absolute_path, root_label))
  end
  return "???"
end

---@private
function Builder:build_header()
  if view.is_root_folder_visible(self.explorer.absolute_path) then
    local root_name = self:format_root_name(self.explorer.opts.renderer.root_folder_label)
    table.insert(self.lines, root_name)
    self:insert_highlight({ "NvimTreeRootFolder" }, 0, string.len(root_name))
    self.index = 1
  end

  if self.explorer.live_filter.filter then
    local filter_line = string.format("%s/%s/", self.explorer.opts.live_filter.prefix, self.explorer.live_filter.filter)
    table.insert(self.lines, filter_line)
    local prefix_length = string.len(self.explorer.opts.live_filter.prefix)
    self:insert_highlight({ "NvimTreeLiveFilterPrefix" }, 0,             prefix_length)
    self:insert_highlight({ "NvimTreeLiveFilterValue" },  prefix_length, string.len(filter_line))
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

---@private
---@param opts table
---@return fun(node: Node): string|nil
function Builder:setup_hidden_display_function(opts)
  local hidden_display = opts.renderer.hidden_display
  -- options are already validated, so ´hidden_display´ can ONLY be `string` or `function` if type(hidden_display) == "string" then
  if type(hidden_display) == "string" then
    if hidden_display == "none" then
      return function()
        return nil
      end
    elseif hidden_display == "simple" then
      return function(hidden_stats)
        return utils.default_format_hidden_count(hidden_stats, true)
      end
    else -- "all"
      return function(hidden_stats)
        return utils.default_format_hidden_count(hidden_stats, false)
      end
    end
  else -- "function
    return function(hidden_stats)
      -- In case of missing field such as live_filter we zero it, otherwise keep field as is
      hidden_stats = vim.tbl_deep_extend("force", {
        live_filter = 0,
        git         = 0,
        buf         = 0,
        dotfile     = 0,
        custom      = 0,
        bookmark    = 0,
      }, hidden_stats or {})

      local ok, result = pcall(hidden_display, hidden_stats)
      if not ok then
        notify.warn(
          "Problem occurred in the function ``opts.renderer.hidden_display`` see nvim-tree.renderer.hidden_display on :h nvim-tree")
        return nil
      end
      return result
    end
  end
end

return Builder
