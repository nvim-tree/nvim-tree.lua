local notify = require("nvim-tree.notify")

local Decorator = require("nvim-tree.renderer.decorator")
local DirectoryNode = require("nvim-tree.node.directory")

---@class (exact) GitHighlightedString: nvim_tree.api.HighlightedString
---@field ord number decreasing priority

---@alias GitStatusStrings "deleted" | "ignored" | "renamed" | "staged" | "unmerged" | "unstaged" | "untracked"

---@alias GitIconsByStatus table<GitStatusStrings, GitHighlightedString> human status
---@alias GitIconsByXY table<nvim_tree.git.XY, GitHighlightedString[]> porcelain status
---@alias GitGlyphsByStatus table<GitStatusStrings, string> from opts

---@class (exact) GitDecorator: Decorator
---@field private explorer Explorer
---@field private file_hl_by_xy table<nvim_tree.git.XY, string>?
---@field private folder_hl_by_xy table<nvim_tree.git.XY, string>?
---@field private icons_by_status GitIconsByStatus?
---@field private icons_by_xy GitIconsByXY?
local GitDecorator = Decorator:extend()

---@class GitDecorator
---@overload fun(args: DecoratorArgs): GitDecorator

---@protected
---@param args DecoratorArgs
function GitDecorator:new(args)
  self.explorer        = args.explorer

  self.enabled         = self.explorer.opts.git.enable
  self.highlight_range = self.explorer.opts.renderer.highlight_git or "none"
  self.icon_placement  = self.explorer.opts.renderer.icons.git_placement or "none"

  if not self.enabled then
    return
  end

  if self.highlight_range ~= "none" then
    self:build_file_folder_hl_by_xy()
  end

  if self.explorer.opts.renderer.icons.show.git then
    self:build_icons_by_status(self.explorer.opts.renderer.icons.glyphs.git)
    self:build_icons_by_xy(self.icons_by_status)

    for _, icon in pairs(self.icons_by_status) do
      self:define_sign(icon)
    end
  end
end

---@param glyphs GitGlyphsByStatus
function GitDecorator:build_icons_by_status(glyphs)
  self.icons_by_status           = {}
  self.icons_by_status.staged    = { str = glyphs.staged, hl = { "NvimTreeGitStagedIcon" }, ord = 1 }
  self.icons_by_status.unstaged  = { str = glyphs.unstaged, hl = { "NvimTreeGitDirtyIcon" }, ord = 2 }
  self.icons_by_status.renamed   = { str = glyphs.renamed, hl = { "NvimTreeGitRenamedIcon" }, ord = 3 }
  self.icons_by_status.deleted   = { str = glyphs.deleted, hl = { "NvimTreeGitDeletedIcon" }, ord = 4 }
  self.icons_by_status.unmerged  = { str = glyphs.unmerged, hl = { "NvimTreeGitMergeIcon" }, ord = 5 }
  self.icons_by_status.untracked = { str = glyphs.untracked, hl = { "NvimTreeGitNewIcon" }, ord = 6 }
  self.icons_by_status.ignored   = { str = glyphs.ignored, hl = { "NvimTreeGitIgnoredIcon" }, ord = 7 }
end

---@param icons GitIconsByStatus
function GitDecorator:build_icons_by_xy(icons)
  self.icons_by_xy = {
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
    dirty  = { icons.unstaged },
  }
end

function GitDecorator:build_file_folder_hl_by_xy()
  self.file_hl_by_xy = {
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
    dirty  = "NvimTreeGitFileDirtyHL",
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
    [" A"] = "NvimTreeGitFileNewHL",
  }

  self.folder_hl_by_xy = {}
  for k, v in pairs(self.file_hl_by_xy) do
    self.folder_hl_by_xy[k] = v:gsub("File", "Folder")
  end
end

---Git icons: git.enable, renderer.icons.show.git and node has status
---@param node Node
---@return HighlightedString[]? icons
function GitDecorator:icons(node)
  if not self.icons_by_xy then
    return nil
  end

  local git_xy = node:get_git_xy()
  if git_xy == nil then
    return nil
  end

  local inserted = {}
  local iconss = {}

  for _, s in pairs(git_xy) do
    local icons = self.icons_by_xy[s]
    if not icons then
      if self.highlight_range == "none" then
        notify.warn(string.format("Unrecognized git state '%s'", git_xy))
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

---Get the first icon as the sign if appropriate
---@param node Node
---@return string|nil name
function GitDecorator:sign_name(node)
  if self.icon_placement ~= "signcolumn" then
    return
  end

  local icons = self:icons(node)
  if icons and #icons > 0 then
    return icons[1].hl[1]
  end
end

---Git highlight: git.enable, renderer.highlight_git and node has status
---@param node Node
---@return string? highlight_group
function GitDecorator:highlight_group(node)
  if self.highlight_range == "none" then
    return nil
  end

  local git_xy = node:get_git_xy()
  if not git_xy then
    return nil
  end

  if node:is(DirectoryNode) then
    return self.folder_hl_by_xy[git_xy[1]]
  else
    return self.file_hl_by_xy[git_xy[1]]
  end
end

return GitDecorator
