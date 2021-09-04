local config = require'nvim-tree.config'
local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local _padding = require'nvim-tree.renderer.padding'
local _help = require'nvim-tree.renderer.help'

local api = vim.api

local lines = {}
local hl = {}
local index = 0
local namespace_id = api.nvim_create_namespace('NvimTreeHighlights')

local icon_state = config.get_icon_state()

local should_hl_opened_files = (vim.g.nvim_tree_highlight_opened_files or 0) ~= 0

local get_folder_icon = function() return "" end
local function get_trailing_length()
  return vim.g.nvim_tree_add_trailing and 1 or 0
end

local set_folder_hl = function(line, depth, git_icon_len, _, hl_group)
  table.insert(hl, {hl_group, line, depth+git_icon_len, -1})
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
    return n..icon_padding
  end
  set_folder_hl = function(line, depth, icon_len, name_len, hl_group)
    table.insert(hl, {hl_group, line, depth+icon_len, depth+icon_len+name_len+get_trailing_length()})
    local hl_icon = (vim.g.nvim_tree_highlight_opened_files or 0) ~= 0 and hl_group or 'NvimTreeFolderIcon'
    table.insert(hl, {hl_icon, line, depth, depth+icon_len})
  end
end

local get_file_icon = function() return "" end
if icon_state.show_file_icon then
  if icon_state.has_devicons then
    local web_devicons = require'nvim-web-devicons'

    get_file_icon = function(fname, extension, line, depth)
      local icon, hl_group = web_devicons.get_icon(fname, extension)

      if icon and hl_group ~= "DevIconDefault" then
        if hl_group then
          table.insert(hl, { hl_group, line, depth, depth + #icon + 1 })
        end
        return icon..icon_padding
      elseif string.match(extension, "%.(.*)") then
        -- If there are more extensions to the file, try to grab the icon for them recursively
        return get_file_icon(fname, string.match(extension, "%.(.*)"), line, depth)
      else
        return #icon_state.icons.default > 0 and icon_state.icons.default..icon_padding or ""
      end
    end
  else
    get_file_icon = function()
      return #icon_state.icons.default > 0 and icon_state.icons.default..icon_padding or ""
    end
  end
end

local get_symlink_icon = function() return icon_state.icons.symlink end
if icon_state.show_file_icon then
  get_symlink_icon = function()
    return #icon_state.icons.symlink > 0 and icon_state.icons.symlink..icon_padding or ""
  end
end

local get_special_icon = function() return "" end
if icon_state.show_file_icon then
  get_special_icon = function()
    return #icon_state.icons.default > 0 and icon_state.icons.default..icon_padding or ""
  end
end

local get_git_icons = function() return "" end
local get_git_hl = function() return end

if vim.g.nvim_tree_git_hl == 1 then
  local git_hl = {
    ["M "] = { { hl = "NvimTreeFileStaged" } },
    [" M"] = { { hl = "NvimTreeFileDirty" } },
    ["CM"] = { { hl = "NvimTreeFileDirty" } },
    ["C "] = { { hl = "NvimTreeFileStaged" } },
    [" C"] = { { hl = "NvimTreeFileDirty" } },
    [" T"] = { { hl = "NvimTreeFileDirty" } },
    ["MM"] = {
      { hl = "NvimTreeFileStaged" },
      { hl = "NvimTreeFileDirty" }
    },
    ["A "] = {
      { hl = "NvimTreeFileStaged" },
      { hl = "NvimTreeFileNew" }
    },
    ["AU"] = {
      { hl = "NvimTreeFileMerge" },
      { hl = "NvimTreeFileStaged" },
    },
    -- not sure about this one
    ["AA"] = {
      { hl = "NvimTreeFileMerge" },
      { hl = "NvimTreeFileStaged" }
    },
    ["AD"] = {
      { hl = "NvimTreeFileStaged" },
    },
    ["MD"] = {
      { hl = "NvimTreeFileStaged" },
    },
    ["AM"] = {
      { hl = "NvimTreeFileStaged" },
      { hl = "NvimTreeFileNew" },
      { hl = "NvimTreeFileDirty" }
    },
    ["??"] = { { hl = "NvimTreeFileNew" } },
    ["R "] = { { hl = "NvimTreeFileRenamed" } },
    ["UU"] = { { hl = "NvimTreeFileMerge" } },
    ["UD"] = { { hl = "NvimTreeFileMerge" } },
    ["UA"] = { { hl = "NvimTreeFileMerge" } },
    [" D"] = { { hl = "NvimTreeFileDeleted" } },
    ["DD"] = { { hl = "NvimTreeFileDeleted" } },
    ["RD"] = { { hl = "NvimTreeFileDeleted" } },
    ["D "] = {
      { hl = "NvimTreeFileDeleted" },
      { hl = "NvimTreeFileStaged" }
    },
    ["DU"] = {
      { hl = "NvimTreeFileDeleted" },
      { hl = "NvimTreeFileMerge" }
    },
    [" A"] = { { hl = "none" } },
    ["RM"] = { { hl = "NvimTreeFileRenamed" } },
    [" R"] = { { hl = "NvimTreeFileRenamed" } },
    ["!!"] = { { hl = "NvimTreeGitIgnored" } },
    dirty = { { hl = "NvimTreeFileDirty" } },
  }
  get_git_hl = function(node)
    local git_status = node.git_status
    if not git_status then return end

    local icons = git_hl[git_status]

    if icons == nil then
      utils.warn('Unrecognized git state "'..git_status..'". Please open up an issue on https://github.com/kyazdani42/nvim-tree.lua/issues with this message.')
      icons = git_hl.dirty
    end

    -- TODO: how would we determine hl color when multiple git status are active ?
    return icons[1].hl
    -- return icons[#icons].hl
  end
end

if icon_state.show_git_icon then
  local git_icon_state = {
    ["M "] = { { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" } },
    [" M"] = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
    ["C "] = { { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" } },
    [" C"] = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
    ["CM"] = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
    [" T"] = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
    ["MM"] = {
      { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
      { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" }
    },
    ["MD"] = {
      { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
    },
    ["A "] = {
      { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
    },
    ["AD"] = {
      { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
    },
    [" A"] = {
      { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" },
    },
    -- not sure about this one
    ["AA"] = {
      { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" },
      { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" },
    },
    ["AU"] = {
      { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" },
      { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" },
    },
    ["AM"] = {
      { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
      { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" }
    },
    ["??"] = { { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" } },
    ["R "] = { { icon = icon_state.icons.git_icons.renamed, hl = "NvimTreeGitRenamed" } },
    [" R"] = { { icon = icon_state.icons.git_icons.renamed, hl = "NvimTreeGitRenamed" } },
    ["RM"] = {
      { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" },
      { icon = icon_state.icons.git_icons.renamed, hl = "NvimTreeGitRenamed" },
    },
    ["UU"] = { { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" } },
    ["UD"] = { { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" } },
    ["UA"] = { { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" } },
    [" D"] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
    ["D "] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
    ["RD"] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
    ["DD"] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
    ["DU"] = {
      { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" },
      { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" },
    },
    ["!!"] = { { icon = icon_state.icons.git_icons.ignored, hl = "NvimTreeGitIgnored" } },
    dirty = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
  }

  get_git_icons = function(node, line, depth, icon_len)
    local git_status = node.git_status
    if not git_status then return "" end

    local icon = ""
    local icons = git_icon_state[git_status]
    if not icons then
      if vim.g.nvim_tree_git_hl ~= 1 then
        utils.warn('Unrecognized git state "'..git_status..'". Please open up an issue on https://github.com/kyazdani42/nvim-tree.lua/issues with this message.')
      end
      icons = git_icon_state.dirty
    end
    for _, v in ipairs(icons) do
      if #v.icon > 0 then
        table.insert(hl, { v.hl, line, depth+icon_len+#icon, depth+icon_len+#icon+#v.icon })
        icon = icon..v.icon..icon_padding
      end
    end

    return icon
  end
end

local picture = {
  jpg = true,
  jpeg = true,
  png = true,
  gif = true,
}

local function update_draw_data(tree, depth, markers)
  local root_folder_modifier = vim.g.nvim_tree_root_folder_modifier or ':~'
  local special = vim.g.nvim_tree_special_files or {
    ["Cargo.toml"] = true,
    Makefile = true,
    ["README.md"] = true,
    ["readme.md"] = true,
  }

  local hide_root_folder = view.View.hide_root_folder

  if tree.cwd and tree.cwd ~= '/' and not hide_root_folder then
    local root_name = utils.path_join({
      utils.path_remove_trailing(vim.fn.fnamemodify(tree.cwd, root_folder_modifier)),
      ".."
    })
    table.insert(lines, root_name)
    table.insert(hl, {'NvimTreeRootFolder', index, 0, string.len(root_name)})
    index = 1
  end

  for idx, node in ipairs(tree.entries) do
    local padding = _padding.get_padding(depth, idx, tree, node, markers)
    local offset = string.len(padding)
    if depth > 0 then
      table.insert(hl, { 'NvimTreeIndentMarker', index, 0, offset })
    end

    local git_hl = get_git_hl(node)
    local filename_start_at

    if node.entries then
      local has_children = #node.entries ~= 0 or node.has_children
      local icon = get_folder_icon(node.open, node.link_to ~= nil, has_children)
      local git_icon = get_git_icons(node, index, offset, #icon+1) or ""
      -- INFO: this is mandatory in order to keep gui attributes (bold/italics)
      local folder_hl = "NvimTreeFolderName"
      local name = node.name
      local next = node.group_next
      while next do
        name = name .. "/" .. next.name
        next = next.group_next
      end
      if not has_children then folder_hl = "NvimTreeEmptyFolderName" end
      if node.open then folder_hl = "NvimTreeOpenedFolderName" end
      if special[node.absolute_path] then
        folder_hl = "NvimTreeSpecialFolderName"
      end
      filename_start_at = offset+#git_icon+#icon
      set_folder_hl(index, offset, #icon, #name+#git_icon, folder_hl)
      if git_hl then
        set_folder_hl(index, offset, #icon, #name+#git_icon, git_hl)
      end
      if node.marked then
        table.insert(hl, { 'NvimTreeMarkedFile', index, filename_start_at, -1 })
      end

      index = index + 1
      if node.open then
        table.insert(lines, padding..icon..git_icon..name..(vim.g.nvim_tree_add_trailing == 1 and '/' or ''))
        update_draw_data(node, depth + 2, markers)
      else
        table.insert(lines, padding..icon..git_icon..name..(vim.g.nvim_tree_add_trailing == 1 and '/' or ''))
      end
    elseif node.link_to then
      local icon = get_symlink_icon()
      local link_hl = git_hl or 'NvimTreeSymlink'
      local arrow = vim.g.nvim_tree_symlink_arrow or ' ➛ '
      filename_start_at = offset
      table.insert(hl, { link_hl, index, filename_start_at, -1 })
      table.insert(lines, padding..icon..node.name..arrow..node.link_to)
      index = index + 1

    else
      local icon
      local git_icons
      if special[node.absolute_path] or special[node.name] then
        icon = get_special_icon()
        git_icons = get_git_icons(node, index, offset, 0)
        table.insert(hl, {'NvimTreeSpecialFile', index, offset+#git_icons, -1})
      else
        icon = get_file_icon(node.name, node.extension, index, offset)
        git_icons = get_git_icons(node, index, offset, #icon)
      end
      table.insert(lines, padding..icon..git_icons..node.name)

      filename_start_at = offset+#git_icons+#icon
      if node.executable then
        table.insert(hl, {'NvimTreeExecFile', index, filename_start_at, -1 })
      elseif picture[node.extension] then
        table.insert(hl, {'NvimTreeImageFile', index, filename_start_at, -1 })
      end

      if should_hl_opened_files then
        if vim.fn.bufloaded(node.absolute_path) > 0 then
          if vim.g.nvim_tree_highlight_opened_files == 1 then
            table.insert(hl, {'NvimTreeOpenedFile', index, offset, offset+#icon })  -- highlight icon only
          elseif vim.g.nvim_tree_highlight_opened_files == 2 then
            table.insert(hl, {'NvimTreeOpenedFile', index, offset+#icon+#git_icons, offset+#icon+#git_icons+#node.name })  -- highlight name only
          elseif vim.g.nvim_tree_highlight_opened_files == 3 then
            table.insert(hl, {'NvimTreeOpenedFile', index, offset, -1 })  -- highlight whole line
          end
        end
      end

      if git_hl then
        table.insert(hl, {git_hl, index, offset+#icon+#git_icons, -1 })
      end
      index = index + 1
    end
    if not node.entries and node.marked then
      table.insert(hl, { 'NvimTreeMarkedFile', index-1, filename_start_at, -1 })
    end
  end
end

local M = {}

function M.draw(tree, reload)
  if not api.nvim_buf_is_loaded(view.View.bufnr) then return end
  local cursor
  if view.win_open() then
    cursor = api.nvim_win_get_cursor(view.get_winnr())
  end
  if reload then
    index = 0
    lines = {}
    hl = {}

    local show_arrows =
      vim.g.nvim_tree_indent_markers ~= 1
      and icon_state.show_folder_icon
      and icon_state.show_folder_arrows
    _padding.reload_padding_function()
    icon_state = config.get_icon_state()
    update_draw_data(tree, show_arrows and 2 or 0, {})
  end

  if view.is_help_ui() then
    lines, hl = _help.compute_lines()
  end
  api.nvim_buf_set_option(view.View.bufnr, 'modifiable', true)
  api.nvim_buf_set_lines(view.View.bufnr, 0, -1, false, lines)
  M.render_hl(view.View.bufnr)
  api.nvim_buf_set_option(view.View.bufnr, 'modifiable', false)

  if cursor and #lines >= cursor[1] then
    api.nvim_win_set_cursor(view.get_winnr(), cursor)
  end
end

function M.render_hl(bufnr)
  if not api.nvim_buf_is_loaded(bufnr) then return end
  api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  for _, data in ipairs(hl) do
    api.nvim_buf_add_highlight(bufnr, namespace_id, data[1], data[2], data[3], data[4])
  end
end

return M
