local notify = require "nvim-tree.notify"
local explorer_node = require "nvim-tree.explorer.node"

local M = {}

local function build_icons_table(i)
  local icons = {
    staged = { str = i.staged, hl = { "NvimTreeGitStaged" }, ord = 1 },
    unstaged = { str = i.unstaged, hl = { "NvimTreeGitDirty" }, ord = 2 },
    renamed = { str = i.renamed, hl = { "NvimTreeGitRenamed" }, ord = 3 },
    deleted = { str = i.deleted, hl = { "NvimTreeGitDeleted" }, ord = 4 },
    unmerged = { str = i.unmerged, hl = { "NvimTreeGitMerge" }, ord = 5 },
    untracked = { str = i.untracked, hl = { "NvimTreeGitNew" }, ord = 6 },
    ignored = { str = i.ignored, hl = { "NvimTreeGitIgnored" }, ord = 7 },
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
    ["A "] = "NvimTreeFileStaged",
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

  local folder = {}
  for k, v in pairs(file) do
    folder[k] = v:gsub("File", "Folder")
  end

  return file, folder
end

local function nil_() end

local function warn_status(git_status)
  notify.warn(string.format("Unrecognized git state '%s'", git_status))
end

---@param node table
---@return HighlightedString[]|nil
local function get_icons_(node)
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
  local git_status = explorer_node.get_git_status(node)
  if git_status == nil then
    return
  end

  if node.nodes then
    return M.folder_hl[git_status[1]]
  else
    return M.file_hl[git_status[1]]
  end
end

function M.setup(opts)
  M.config = opts.renderer

  M.git_icons = build_icons_table(opts.renderer.icons.glyphs.git)

  M.file_hl, M.folder_hl = build_hl_table()

  if opts.renderer.icons.git_placement == "signcolumn" then
    M.setup_signs(opts.renderer.icons.glyphs.git)
  end

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
