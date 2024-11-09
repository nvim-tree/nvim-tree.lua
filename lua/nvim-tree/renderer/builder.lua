local notify = require("nvim-tree.notify")
local utils = require("nvim-tree.utils")
local view = require("nvim-tree.view")

local Class = require("nvim-tree.classic")
local DirectoryNode = require("nvim-tree.node.directory")

local DecoratorBookmarks = require("nvim-tree.renderer.decorator.bookmarks")
local DecoratorCopied = require("nvim-tree.renderer.decorator.copied")
local DecoratorCut = require("nvim-tree.renderer.decorator.cut")
local DecoratorDiagnostics = require("nvim-tree.renderer.decorator.diagnostics")
local DecoratorGit = require("nvim-tree.renderer.decorator.git")
local DecoratorModified = require("nvim-tree.renderer.decorator.modified")
local DecoratorHidden = require("nvim-tree.renderer.decorator.hidden")
local DecoratorOpened = require("nvim-tree.renderer.decorator.opened")

local pad = require("nvim-tree.renderer.components.padding")

---@class (exact) HighlightedString
---@field str string
---@field hl string[]

---@class (exact) AddHighlightArgs
---@field group string[]
---@field line number
---@field col_start number
---@field col_end number

---@class (exact) Builder
---@field lines string[] includes icons etc.
---@field hl_args AddHighlightArgs[] line highlights
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
  self.hl_args         = {}
  self.combined_groups = {}
  self.lines           = {}
  self.markers         = {}
  self.signs           = {}
  self.extmarks        = {}
  self.virtual_lines   = {}
  self.decorators      = {
    -- priority order
    DecoratorCut({ explorer = args.explorer }),
    DecoratorCopied({ explorer = args.explorer }),
    DecoratorDiagnostics({ explorer = args.explorer }),
    DecoratorBookmarks({ explorer = args.explorer }),
    DecoratorModified({ explorer = args.explorer }),
    DecoratorHidden({ explorer = args.explorer }),
    DecoratorOpened({ explorer = args.explorer }),
    DecoratorGit({ explorer = args.explorer })
  }
  self.hidden_display  = Builder:setup_hidden_display_function(self.explorer.opts)
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

  local line = { indent_markers, arrows }
  add_to_end(line, { icon })

  for i = #self.decorators, 1, -1 do
    add_to_end(line, self.decorators[i]:icons_before(node))
  end

  add_to_end(line, { name })

  for i = #self.decorators, 1, -1 do
    add_to_end(line, self.decorators[i]:icons_after(node))
  end

  local rights = {}
  for i = #self.decorators, 1, -1 do
    add_to_end(rights, self.decorators[i]:icons_right_align(node))
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
  for _, d in ipairs(self.decorators) do
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
  for i = #self.decorators, 1, -1 do
    d = self.decorators[i]
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

---Insert node line into self.lines, calling Builder:build_lines for each directory
---@private
---@param node Node
---@param idx integer line number starting at 1
---@param num_children integer of node
function Builder:build_line(node, idx, num_children)
  -- various components
  local indent_markers = pad.get_indent_markers(self.depth, idx, num_children, node, self.markers)
  local arrows = pad.get_arrows(node)

  -- main components
  local icon, name = node:highlighted_icon(), node:highlighted_name()

  -- highighting
  local icon_hl_group, name_hl_group = self:add_highlights(node)
  table.insert(icon.hl, icon_hl_group)
  table.insert(name.hl, name_hl_group)

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
