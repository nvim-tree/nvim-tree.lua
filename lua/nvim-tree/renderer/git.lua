local _icons = require "nvim-tree.renderer.icons"
local utils = require "nvim-tree.utils"

local M = {}

local function build_icons_table()
  local i = M.icon_state.icons.git_icons
  return {
    ["M "] = { { icon = i.staged, hl = "NvimTreeGitStaged" } },
    [" M"] = { { icon = i.unstaged, hl = "NvimTreeGitDirty" } },
    ["C "] = { { icon = i.staged, hl = "NvimTreeGitStaged" } },
    [" C"] = { { icon = i.unstaged, hl = "NvimTreeGitDirty" } },
    ["CM"] = { { icon = i.unstaged, hl = "NvimTreeGitDirty" } },
    [" T"] = { { icon = i.unstaged, hl = "NvimTreeGitDirty" } },
    ["T "] = { { icon = i.staged, hl = "NvimTreeGitStaged" } },
    ["MM"] = {
      { icon = i.staged, hl = "NvimTreeGitStaged" },
      { icon = i.unstaged, hl = "NvimTreeGitDirty" },
    },
    ["MD"] = {
      { icon = i.staged, hl = "NvimTreeGitStaged" },
    },
    ["A "] = {
      { icon = i.staged, hl = "NvimTreeGitStaged" },
    },
    ["AD"] = {
      { icon = i.staged, hl = "NvimTreeGitStaged" },
    },
    [" A"] = {
      { icon = i.untracked, hl = "NvimTreeGitNew" },
    },
    -- not sure about this one
    ["AA"] = {
      { icon = i.unmerged, hl = "NvimTreeGitMerge" },
      { icon = i.untracked, hl = "NvimTreeGitNew" },
    },
    ["AU"] = {
      { icon = i.unmerged, hl = "NvimTreeGitMerge" },
      { icon = i.untracked, hl = "NvimTreeGitNew" },
    },
    ["AM"] = {
      { icon = i.staged, hl = "NvimTreeGitStaged" },
      { icon = i.unstaged, hl = "NvimTreeGitDirty" },
    },
    ["??"] = { { icon = i.untracked, hl = "NvimTreeGitNew" } },
    ["R "] = { { icon = i.renamed, hl = "NvimTreeGitRenamed" } },
    [" R"] = { { icon = i.renamed, hl = "NvimTreeGitRenamed" } },
    ["RM"] = {
      { icon = i.unstaged, hl = "NvimTreeGitDirty" },
      { icon = i.renamed, hl = "NvimTreeGitRenamed" },
    },
    ["UU"] = { { icon = i.unmerged, hl = "NvimTreeGitMerge" } },
    ["UD"] = { { icon = i.unmerged, hl = "NvimTreeGitMerge" } },
    ["UA"] = { { icon = i.unmerged, hl = "NvimTreeGitMerge" } },
    [" D"] = { { icon = i.deleted, hl = "NvimTreeGitDeleted" } },
    ["D "] = { { icon = i.deleted, hl = "NvimTreeGitDeleted" } },
    ["RD"] = { { icon = i.deleted, hl = "NvimTreeGitDeleted" } },
    ["DD"] = { { icon = i.deleted, hl = "NvimTreeGitDeleted" } },
    ["DU"] = {
      { icon = i.deleted, hl = "NvimTreeGitDeleted" },
      { icon = i.unmerged, hl = "NvimTreeGitMerge" },
    },
    ["!!"] = { { icon = i.ignored, hl = "NvimTreeGitIgnored" } },
    dirty = { { icon = i.unstaged, hl = "NvimTreeGitDirty" } },
  }
end

local function empty()
  return ""
end
local function nil_() end

local function warn_status(git_status)
  utils.warn(
    'Unrecognized git state "'
      .. git_status
      .. '". Please open up an issue on https://github.com/kyazdani42/nvim-tree.lua/issues with this message.'
  )
end

local function get_icons_(node, line, depth, icon_len, hl)
  local git_status = node.git_status
  if not git_status then
    return ""
  end

  local icon = ""
  local icons = M.git_icons[git_status]
  if not icons then
    if vim.g.nvim_tree_git_hl ~= 1 then
      warn_status(git_status)
    end
    return ""
  end
  for _, v in ipairs(icons) do
    if #v.icon > 0 then
      table.insert(hl, { v.hl, line, depth + icon_len + #icon, depth + icon_len + #icon + #v.icon })
      icon = icon .. v.icon .. M.icon_padding
    end
  end

  return icon
end

local git_hl = {
  ["M "] = "NvimTreeFileStaged",
  ["C "] = "NvimTreeFileStaged",
  ["AA"] = "NvimTreeFileStaged",
  ["AD"] = "NvimTreeFileStaged",
  ["MD"] = "NvimTreeFileStaged",
  ["T "] = "NvimTreeFileStaged",
  [" M"] = "NvimTreeFileDirty",
  ["CM"] = "NvimTreeFileDirty",
  [" C"] = "NvimTreeFileDirty",
  [" T"] = "NvimTreeFileDirty",
  ["MM"] = "NvimTreeFileDirty",
  ["AM"] = "NvimTreeFileDirty",
  dirty = "NvimTreeFileDirty",
  ["A "] = "NvimTreeFileNew",
  ["??"] = "NvimTreeFileNew",
  ["AU"] = "NvimTreeFileMerge",
  ["UU"] = "NvimTreeFileMerge",
  ["UD"] = "NvimTreeFileMerge",
  ["DU"] = "NvimTreeFileMerge",
  ["UA"] = "NvimTreeFileMerge",
  [" D"] = "NvimTreeFileDeleted",
  ["DD"] = "NvimTreeFileDeleted",
  ["RD"] = "NvimTreeFileDeleted",
  ["D "] = "NvimTreeFileDeleted",
  ["R "] = "NvimTreeFileRenamed",
  ["RM"] = "NvimTreeFileRenamed",
  [" R"] = "NvimTreeFileRenamed",
  ["!!"] = "NvimTreeGitIgnored",
  [" A"] = "none",
}

local function get_highlight_(node)
  local git_status = node.git_status
  if not git_status then
    return
  end

  return git_hl[git_status]
end

function M.get_icons()
  return empty()
end

function M.get_highlight()
  return nil_()
end

M.icon_padding = vim.g.nvim_tree_icon_padding or " "
M.icon_state = _icons.get_config()
M.git_icons = build_icons_table()

function M.reload()
  M.icon_state = _icons.get_config()
  M.icon_padding = vim.g.nvim_tree_icon_padding or " "
  M.git_icons = build_icons_table()
  if M.icon_state.show_git_icon then
    M.get_icons = get_icons_
  else
    M.get_icons = empty
  end
  if vim.g.nvim_tree_git_hl == 1 then
    M.get_highlight = get_highlight_
  else
    M.get_highlight = nil_
  end
end

return M
