return {
  ["M "] = { { icon = 'staged', hl = "NvimTreeGitStaged" } },
  [" M"] = { { icon = 'unstaged', hl = "NvimTreeGitDirty" } },
  ["C "] = { { icon = 'staged', hl = "NvimTreeGitStaged" } },
  [" C"] = { { icon = 'unstaged', hl = "NvimTreeGitDirty" } },
  [" T"] = { { icon = 'unstaged', hl = "NvimTreeGitDirty" } },
  ["MM"] = {
    { icon = 'staged', hl = "NvimTreeGitStaged" },
    { icon = 'unstaged', hl = "NvimTreeGitDirty" }
  },
  ["MD"] = {{ icon = 'staged', hl = "NvimTreeGitStaged" }},
  ["A "] = {{ icon = 'staged', hl = "NvimTreeGitStaged" }},
  ["AD"] = {{ icon = 'staged', hl = "NvimTreeGitStaged" }},
  [" A"] = {{ icon = 'untracked', hl = "NvimTreeGitNew" }},
  -- not sure about this one
  ["AA"] = {
    { icon = 'unmerged', hl = "NvimTreeGitMerge" },
    { icon = 'untracked', hl = "NvimTreeGitNew" },
  },
  ["AU"] = {
    { icon = 'unmerged', hl = "NvimTreeGitMerge" },
    { icon = 'untracked', hl = "NvimTreeGitNew" },
  },
  ["AM"] = {
    { icon = 'staged', hl = "NvimTreeGitStaged" },
    { icon = 'unstaged', hl = "NvimTreeGitDirty" }
  },
  ["??"] = { { icon = 'untracked', hl = "NvimTreeGitNew" } },
  ["R "] = { { icon = 'renamed', hl = "NvimTreeGitRenamed" } },
  [" R"] = { { icon = 'renamed', hl = "NvimTreeGitRenamed" } },
  ["RM"] = {
    { icon = 'unstaged', hl = "NvimTreeGitDirty" },
    { icon = 'renamed', hl = "NvimTreeGitRenamed" },
  },
  ["UU"] = { { icon = 'unmerged', hl = "NvimTreeGitMerge" } },
  ["UD"] = { { icon = 'unmerged', hl = "NvimTreeGitMerge" } },
  ["UA"] = { { icon = 'unmerged', hl = "NvimTreeGitMerge" } },
  [" D"] = { { icon = 'deleted', hl = "NvimTreeGitDeleted" } },
  ["D "] = { { icon = 'deleted', hl = "NvimTreeGitDeleted" } },
  ["RD"] = { { icon = 'deleted', hl = "NvimTreeGitDeleted" } },
  ["DD"] = { { icon = 'deleted', hl = "NvimTreeGitDeleted" } },
  ["DU"] = {
    { icon = 'deleted', hl = "NvimTreeGitDeleted" },
    { icon = 'unmerged', hl = "NvimTreeGitMerge" },
  },
  ["!!"] = { { icon = 'ignored', hl = "NvimTreeGitIgnored" } },
  dirty = { { icon = 'unstaged', hl = "NvimTreeGitDirty" } },
}
