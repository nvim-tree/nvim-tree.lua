local notify = require "nvim-tree.notify"
local explorer_node = require "nvim-tree.explorer.node"

local HL_POSITION = require("nvim-tree.enum").HL_POSITION

local M = {
  -- position for HL
  HL_POS = HL_POSITION.none,
}

local function build_icons_table(i)
  local icons = {
    staged = { str = i.staged, hl = { "NvimTreeGitStagedIcon" }, ord = 1 },
    unstaged = { str = i.unstaged, hl = { "NvimTreeGitDirtyIcon" }, ord = 2 },
    renamed = { str = i.renamed, hl = { "NvimTreeGitRenamedIcon" }, ord = 3 },
    deleted = { str = i.deleted, hl = { "NvimTreeGitDeletedIcon" }, ord = 4 },
    unmerged = { str = i.unmerged, hl = { "NvimTreeGitMergeIcon" }, ord = 5 },
    untracked = { str = i.untracked, hl = { "NvimTreeGitNewIcon" }, ord = 6 },
    ignored = { str = i.ignored, hl = { "NvimTreeGitIgnoredIcon" }, ord = 7 },
  }
  return {
    ["M "] = { icons.staged },
    [" M"] = { icons.unstaged },
    ["C "] = { icons.staged },
    [" C"] = { icons.unstaged },
    ["CM"] = { icons.unstaged },
    [" T"] = { icons.unstaged },
    ["T "] = { icons.staged },
    ["TM"] = { icons.staged, icons.unstaged },
    ["MM"] = { icons.staged, icons.unstaged },
    ["MD"] = { icons.staged },
    ["A "] = { icons.staged },
    ["AD"] = { icons.staged },
    [" A"] = { icons.untracked },
    -- not sure about this one
    ["AA"] = { icons.unmerged, icons.untracked },
    ["AU"] = { icons.unmerged, icons.untracked },
    ["AM"] = { icons.staged, icons.unstaged },
    ["??"] = { icons.untracked },
    ["R "] = { icons.renamed },
    [" R"] = { icons.renamed },
    ["RM"] = { icons.unstaged, icons.renamed },
    ["UU"] = { icons.unmerged },
    ["UD"] = { icons.unmerged },
    ["UA"] = { icons.unmerged },
    [" D"] = { icons.deleted },
    ["D "] = { icons.deleted },
    ["DA"] = { icons.unstaged },
    ["RD"] = { icons.deleted },
    ["DD"] = { icons.deleted },
    ["DU"] = { icons.deleted, icons.unmerged },
    ["!!"] = { icons.ignored },
    dirty = { icons.unstaged },
  }
end

local function build_hl_table()
  local file = {
    ["M "] = "NvimTreeGitFileStagedHL",
    ["C "] = "NvimTreeGitFileStagedHL",
    ["AA"] = "NvimTreeGitFileStagedHL",
    ["AD"] = "NvimTreeGitFileStagedHL",
    ["MD"] = "NvimTreeGitFileStagedHL",
    ["T "] = "NvimTreeGitFileStagedHL",
    ["TT"] = "NvimTreeGitFileStagedHL",
    [" M"] = "NvimTreeGitFileDirtyHL",
    ["CM"] = "NvimTreeGitFileDirtyHL",
    [" C"] = "NvimTreeGitFileDirtyHL",
    [" T"] = "NvimTreeGitFileDirtyHL",
    ["MM"] = "NvimTreeGitFileDirtyHL",
    ["AM"] = "NvimTreeGitFileDirtyHL",
    dirty = "NvimTreeGitFileDirtyHL",
    ["A "] = "NvimTreeGitFileStagedHL",
    ["??"] = "NvimTreeGitFileNewHL",
    ["AU"] = "NvimTreeGitFileMergeHL",
    ["UU"] = "NvimTreeGitFileMergeHL",
    ["UD"] = "NvimTreeGitFileMergeHL",
    ["DU"] = "NvimTreeGitFileMergeHL",
    ["UA"] = "NvimTreeGitFileMergeHL",
    [" D"] = "NvimTreeGitFileDeletedHL",
    ["DD"] = "NvimTreeGitFileDeletedHL",
    ["RD"] = "NvimTreeGitFileDeletedHL",
    ["D "] = "NvimTreeGitFileDeletedHL",
    ["R "] = "NvimTreeGitFileRenamedHL",
    ["RM"] = "NvimTreeGitFileRenamedHL",
    [" R"] = "NvimTreeGitFileRenamedHL",
    ["!!"] = "NvimTreeGitFileIgnoredHL",
    [" A"] = "none",
  }

  local folder = {}
  for k, v in pairs(file) do
    folder[k] = v:gsub("File", "Folder")
  end

  return file, folder
end

local function setup_signs(i)
  vim.fn.sign_define("NvimTreeGitDirtyIcon", { text = i.unstaged, texthl = "NvimTreeGitDirtyIcon" })
  vim.fn.sign_define("NvimTreeGitStagedIcon", { text = i.staged, texthl = "NvimTreeGitStagedIcon" })
  vim.fn.sign_define("NvimTreeGitMergeIcon", { text = i.unmerged, texthl = "NvimTreeGitMergeIcon" })
  vim.fn.sign_define("NvimTreeGitRenamedIcon", { text = i.renamed, texthl = "NvimTreeGitRenamedIcon" })
  vim.fn.sign_define("NvimTreeGitNewIcon", { text = i.untracked, texthl = "NvimTreeGitNewIcon" })
  vim.fn.sign_define("NvimTreeGitDeletedIcon", { text = i.deleted, texthl = "NvimTreeGitDeletedIcon" })
  vim.fn.sign_define("NvimTreeGitIgnoredIcon", { text = i.ignored, texthl = "NvimTreeGitIgnoredIcon" })
end

local function warn_status(git_status)
  notify.warn(string.format("Unrecognized git state '%s'", git_status))
end

---@param node table
---@return HighlightedString[]|nil
function M.get_icons(node)
  if not M.config.icons.show.git then
    return nil
  end

  local git_status = explorer_node.get_git_status(node)
  if git_status == nil then
    return nil
  end

  local inserted = {}
  local iconss = {}

  for _, s in pairs(git_status) do
    local icons = M.git_icons[s]
    if not icons then
      if not M.config.highlight_git then
        warn_status(s)
      end
      return nil
    end

    for _, icon in pairs(icons) do
      if #icon.str > 0 then
        if not inserted[icon] then
          table.insert(iconss, icon)
          inserted[icon] = true
        end
      end
    end
  end

  if #iconss == 0 then
    return nil
  end

  -- sort icons so it looks slightly better
  table.sort(iconss, function(a, b)
    return a.ord < b.ord
  end)

  return iconss
end

---Git highlight group and position when highlight_git
---@param node table
---@return HL_POSITION position none when no status
---@return string|nil group only when status
function M.get_highlight(node)
  if not node or M.HL_POS == HL_POSITION.none then
    return HL_POSITION.none, nil
  end

  local git_status = explorer_node.get_git_status(node)
  if not git_status then
    return HL_POSITION.none, nil
  end

  if node.nodes then
    return M.HL_POS, M.folder_hl[git_status[1]]
  else
    return M.HL_POS, M.file_hl[git_status[1]]
  end
end

function M.setup(opts)
  M.config = opts.renderer

  M.git_icons = build_icons_table(opts.renderer.icons.glyphs.git)

  M.file_hl, M.folder_hl = build_hl_table()

  setup_signs(opts.renderer.icons.glyphs.git)

  if opts.git.enable and opts.renderer.highlight_git then
    M.HL_POS = HL_POSITION[opts.renderer.highlight_git]
  end
end

return M
