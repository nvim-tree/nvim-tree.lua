local notify = require "nvim-tree.notify"

local M = {
  SIGN_GROUP = "NvimTreeGitSigns",
}

local function build_icons_table(i)
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

local function nil_() end

local function warn_status(git_status)
  notify.warn(
    'Unrecognized git state "'
      .. git_status
      .. '". Please open up an issue on https://github.com/nvim-tree/nvim-tree.lua/issues with this message.'
  )
end

local function show_git(node)
  return node.git_status and (not node.open or M.git_show_on_open_dirs)
end

local function get_icons_(node)
  local git_status = node.git_status
  if not show_git(node) then
    return nil
  end

  local icons = M.git_icons[git_status]
  if not icons then
    if not M.config.highlight_git then
      warn_status(git_status)
    end
    return nil
  end

  return icons
end

local git_hl = {
  ["M "] = "NvimTreeFileStaged",
  ["C "] = "NvimTreeFileStaged",
  ["AA"] = "NvimTreeFileStaged",
  ["AD"] = "NvimTreeFileStaged",
  ["MD"] = "NvimTreeFileStaged",
  ["T "] = "NvimTreeFileStaged",
  ["TT"] = "NvimTreeFileStaged",
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
  ["!!"] = "NvimTreeFileIgnored",
  [" A"] = "none",
}

function M.setup_signs(i)
  vim.fn.sign_define("NvimTreeGitDirty", { text = i.unstaged, texthl = "NvimTreeGitDirty" })
  vim.fn.sign_define("NvimTreeGitStaged", { text = i.staged, texthl = "NvimTreeGitStaged" })
  vim.fn.sign_define("NvimTreeGitMerge", { text = i.unmerged, texthl = "NvimTreeGitMerge" })
  vim.fn.sign_define("NvimTreeGitRenamed", { text = i.renamed, texthl = "NvimTreeGitRenamed" })
  vim.fn.sign_define("NvimTreeGitNew", { text = i.untracked, texthl = "NvimTreeGitNew" })
  vim.fn.sign_define("NvimTreeGitDeleted", { text = i.deleted, texthl = "NvimTreeGitDeleted" })
  vim.fn.sign_define("NvimTreeGitIgnored", { text = i.ignored, texthl = "NvimTreeGitIgnored" })
end

local function get_highlight_(node)
  local git_status = node.git_status
  if not show_git(node) then
    return
  end

  return git_hl[git_status]
end

function M.setup(opts)
  M.config = opts.renderer

  M.git_icons = build_icons_table(opts.renderer.icons.glyphs.git)

  M.setup_signs(opts.renderer.icons.glyphs.git)

  if opts.renderer.icons.show.git then
    M.get_icons = get_icons_
  else
    M.get_icons = nil_
  end

  if opts.renderer.highlight_git then
    M.get_highlight = get_highlight_
  else
    M.get_highlight = nil_
  end

  M.git_show_on_open_dirs = opts.git.show_on_open_dirs
end

return M
