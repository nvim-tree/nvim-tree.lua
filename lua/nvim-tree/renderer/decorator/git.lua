local notify = require "nvim-tree.notify"
local explorer_node = require "nvim-tree.explorer.node"

local HL_POSITION = require("nvim-tree.enum").HL_POSITION
local ICON_PLACEMENT = require("nvim-tree.enum").ICON_PLACEMENT

local Decorator = require "nvim-tree.renderer.decorator"

---@class HighlightedStringGit: HighlightedString
---@field ord number decreasing priority

---@class DecoratorGit: Decorator
---@field file_hl table<string, string> by porcelain status e.g. "AM"
---@field folder_hl table<string, string> by porcelain status
---@field icons_by_status HighlightedStringGit[] by human status
---@field icons_by_xy table<string, HighlightedStringGit[]> by porcelain status
local DecoratorGit = Decorator:new()

---@param opts table
---@return DecoratorGit
function DecoratorGit:new(opts)
  local o = Decorator.new(self, {
    enabled = opts.git.enable,
    hl_pos = HL_POSITION[opts.renderer.highlight_git] or HL_POSITION.none,
    icon_placement = ICON_PLACEMENT[opts.renderer.icons.git_placement] or ICON_PLACEMENT.none,
  })
  ---@cast o DecoratorGit

  if not o.enabled then
    return o
  end

  if o.hl_pos ~= HL_POSITION.none then
    o:build_hl_table()
  end

  if opts.renderer.icons.show.git then
    o:build_icons_by_status(opts.renderer.icons.glyphs.git)
    o:build_icons_by_xy(o.icons_by_status)

    for _, icon in pairs(o.icons_by_status) do
      self:define_sign(icon)
    end
  end

  return o
end

---@param glyphs table<string, string> user glyps
function DecoratorGit:build_icons_by_status(glyphs)
  self.icons_by_status = {
    staged = { str = glyphs.staged, hl = { "NvimTreeGitStagedIcon" }, ord = 1 },
    unstaged = { str = glyphs.unstaged, hl = { "NvimTreeGitDirtyIcon" }, ord = 2 },
    renamed = { str = glyphs.renamed, hl = { "NvimTreeGitRenamedIcon" }, ord = 3 },
    deleted = { str = glyphs.deleted, hl = { "NvimTreeGitDeletedIcon" }, ord = 4 },
    unmerged = { str = glyphs.unmerged, hl = { "NvimTreeGitMergeIcon" }, ord = 5 },
    untracked = { str = glyphs.untracked, hl = { "NvimTreeGitNewIcon" }, ord = 6 },
    ignored = { str = glyphs.ignored, hl = { "NvimTreeGitIgnoredIcon" }, ord = 7 },
  }
end

---@param icons HighlightedStringGit[]
function DecoratorGit:build_icons_by_xy(icons)
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
    dirty = { icons.unstaged },
  }
end

function DecoratorGit:build_hl_table()
  self.file_hl = {
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

  self.folder_hl = {}
  for k, v in pairs(self.file_hl) do
    self.folder_hl[k] = v:gsub("File", "Folder")
  end
end

---Git icons: git.enable, renderer.icons.show.git and node has status
---@param node Node
---@return HighlightedString[]|nil modified icon
function DecoratorGit:calculate_icons(node)
  if not node or not self.enabled or not self.icons_by_xy then
    return nil
  end

  local git_status = explorer_node.get_git_status(node)
  if git_status == nil then
    return nil
  end

  local inserted = {}
  local iconss = {}

  for _, s in pairs(git_status) do
    local icons = self.icons_by_xy[s]
    if not icons then
      if self.hl_pos == HL_POSITION.none then
        notify.warn(string.format("Unrecognized git state '%s'", git_status))
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
function DecoratorGit:sign_name(node)
  if self.icon_placement ~= ICON_PLACEMENT.signcolumn then
    return
  end

  local icons = self:calculate_icons(node)
  if icons and #icons > 0 then
    return icons[1].hl[1]
  end
end

---Git highlight: git.enable, renderer.highlight_git and node has status
---@param node Node
---@return string|nil group
function DecoratorGit:calculate_highlight(node)
  if not node or not self.enabled or self.hl_pos == HL_POSITION.none then
    return nil
  end

  local git_status = explorer_node.get_git_status(node)
  if not git_status then
    return nil
  end

  if node.nodes then
    return self.folder_hl[git_status[1]]
  else
    return self.file_hl[git_status[1]]
  end
end

return DecoratorGit
