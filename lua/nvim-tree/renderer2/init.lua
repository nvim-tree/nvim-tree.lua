-- TODO: move options from config to here in the setup
-- also find a way to make coloring better
-- also need to reimplement the grouping with the skip property

-- PERF: components can be optimized by loading the function separately instead of having a lot of if branches
-- but overall its still quite fast, but just better written an overridable
-- which means user can just override the components.git to make their custom git display !
local a = vim.api

local view = require'nvim-tree.view'
local config = require'nvim-tree.config'
local utils = require'nvim-tree.utils'
local components = require'nvim-tree.renderer2.components'

local M = {
  renderer = nil,
  namespace_id = a.nvim_create_namespace('NvimTree')
}

local Renderer = {}
Renderer.__index = Renderer

function Renderer:add_line(line)
  table.insert(self.lines, line)
end

function Renderer:add_highlight(highlight)
  table.insert(self.highlights, highlight)
end

function Renderer:get_padding(idx, node, nodes)
  return components.padding(
    idx,
    node,
    nodes,
    self.depth,
    self.markers,
    M.config.indent_level,
    M.config.show_folder_arrows,
    M.config.indent_markers,
    M.config.icons.folder_icons
  )
end

function Renderer:load_git_icons(node)
  return components.git(
    node,
    M.config.icons.git_icons
  )
end

function Renderer:load_ft_icon(node)
  return components.icon(
    node,
    M.config.icons,
    M.config.show_folder_icon,
    M.config.show_file_icon,
    M.config.has_devicons
  )
end

function Renderer:load_name(node)
  return components.name(
    node,
    M.config.pictures,
    M.config.special_files
  )
end

function Renderer:load_line(idx, node, nodes)
  if self.skip > 0 then
    self.skip = self.skip - 1
    return
  end

  local padding = self:get_padding(idx, node, nodes)

  if self.depth > 0 then
    self:add_highlight({ 'NvimTreeIndentMarker', self.index, 0, #padding })
  end

  local ft_icon_info = self:load_ft_icon(node)
  if ft_icon_info.highlight then
    local c_start = #padding
    local c_end = #padding + #ft_icon_info.display
    self:add_highlight({ft_icon_info.highlight, self.index, c_start, c_end })
  end

  local git_icons_and_highlight = self:load_git_icons(node)
  local git_icons = vim.tbl_map(function(n) return n.icon end, git_icons_and_highlight)
  local git_display = ''
  if #git_icons_and_highlight > 0 then
    git_display = table.concat(git_icons, ' ')..' '
    local c_start = #padding + #ft_icon_info.display
    for _, n in ipairs(git_icons_and_highlight) do
      local c_end = c_start + #n.icon
      self:add_highlight({n.highlight, self.index, c_start, c_end })
      c_start = c_end + 1
    end
  end

  -- TODO: git highlight override
  local name_info = self:load_name(node)
  if name_info.highlight then
    local c_start = #padding + #ft_icon_info.display + #git_display
    local c_end = c_start + #name_info.display
    self:add_highlight({name_info.highlight, self.index, c_start, c_end })
  end

  self:add_line(padding..ft_icon_info.display..git_display..name_info.display)

  self.index = self.index + 1

  if node.open and #node.entries > 0 then
    self.depth = self.depth + M.config.indent_level
    self:load_lines(node.entries)
    self.depth = self.depth - M.config.indent_level
  end

end

function Renderer:load_lines(entries)
  for idx, node in ipairs(entries) do
    self:load_line(idx, node, entries)
  end
end

function Renderer:load_root_folder()
  local modified = vim.fn.fnamemodify(self.tree.cwd, M.config.root_folder_modifier)
  local root_name = utils.path_join({utils.path_remove_trailing(modified), '..'})

  self:add_line(root_name)
  self:add_highlight({'NvimTreeRootFolder', self.index, 0, #root_name})
  self.index = 1
end

function Renderer:load_tree()
  if not view.View.hide_root_folder and self.tree.cwd ~= '/' then
    self:load_root_folder()
  end

  self:load_lines(self.tree.entries)
end

function Renderer:load_help()
  local lines, highlights = require'nvim-tree.renderer.help'.compute_lines()
  self.lines = lines
  self.highlights = highlights
end

function Renderer.new(opts)
  local renderer = setmetatable({
    tree = opts.tree,
    lines = {},
    highlights = {},
    index = 0,
    skip = 0,
    markers = {},
    depth = M.config.show_folder_arrows and M.config.indent_level or 0
  }, Renderer)

  if opts.help then
    renderer:load_help()
  else
    renderer:load_tree()
  end

  return renderer
end

function Renderer:to_buf(bufnr)
  a.nvim_buf_set_option(bufnr, 'modifiable', true)

  a.nvim_buf_clear_namespace(bufnr, M.namespace_id, 0, -1)

  a.nvim_buf_set_lines(bufnr, 0, -1, false, self.lines)

  for _, data in ipairs(self.highlights) do
    a.nvim_buf_add_highlight(bufnr, M.namespace_id, data[1], data[2], data[3], data[4])
  end

  a.nvim_buf_set_option(bufnr, 'modifiable', false)
end

function M.draw(tree, reload)
  if not a.nvim_buf_is_loaded(view.View.bufnr) then
    return
  end

  local cursor = view.win_open() and a.nvim_win_get_cursor(view.get_winnr())

  if reload or not M.renderer then
    M.renderer = Renderer.new {
      help = view.is_help_ui(),
      tree = tree,
    }
  end

  M.renderer:to_buf(view.View.bufnr)

  if cursor and #M.renderer.lines >= cursor[1] then
    view.set_cursor(cursor)
  end
end

function M.setup(opts)
  local icon_config = config.get_icon_state()
  M.config = {
    icons = icon_config.icons,
    show_file_icon = icon_config.show_file_icon,
    show_folder_icon = icon_config.show_folder_icon,
    show_git_icon = icon_config.show_git_icon,
    show_folder_arrows = icon_config.show_folder_arrows,
    has_devicons = icon_config.has_devicons,
    highlight_opened_files = vim.g.nvim_tree_highlight_opened_files == 1,
    root_folder_modifier = vim.g.nvim_tree_root_folder_modifier or ':~',
    indent_markers = vim.g.nvim_tree_indent_markers == 1,
    indent_level = opts.renderer.indent_level,
    special_files = vim.g.nvim_tree_special_files or {
      ["Cargo.toml"] = true,
      Makefile = true,
      ["README.md"] = true,
      ["readme.md"] = true,
    },
    pictures = {
      jpg = true,
      jpeg = true,
      png = true,
      gif = true,
    }
  }
end

return M
