local M = {}

---@class HighlightGroup
---@field group string
---@field link string|nil
---@field def string|nil

---@type HighlightGroup[]
-- All highlight groups: linked or directly defined.
-- Please add new groups to help and preserve order.
-- Please avoid directly defined groups to preserve accessibility for TUI.
M.HIGHLIGHT_GROUPS = {

  -- Standard
  { group = "NvimTreeNormal",                  link = "Normal" },
  { group = "NvimTreeNormalFloat",             link = "NormalFloat" },
  { group = "NvimTreeNormalFloatBorder",       link = "FloatBorder" },
  { group = "NvimTreeNormalNC",                link = "NvimTreeNormal" },

  { group = "NvimTreeLineNr",                  link = "LineNr" },
  { group = "NvimTreeWinSeparator",            link = "WinSeparator" },
  { group = "NvimTreeEndOfBuffer",             link = "EndOfBuffer" },
  { group = "NvimTreePopup",                   link = "Normal" },
  { group = "NvimTreeSignColumn",              link = "NvimTreeNormal" },

  { group = "NvimTreeCursorColumn",            link = "CursorColumn" },
  { group = "NvimTreeCursorLine",              link = "CursorLine" },
  { group = "NvimTreeCursorLineNr",            link = "CursorLineNr" },

  { group = "NvimTreeStatusLine",              link = "StatusLine" },
  { group = "NvimTreeStatusLineNC",            link = "StatusLineNC" },

  -- File Text
  { group = "NvimTreeExecFile",                link = "Question" },
  { group = "NvimTreeImageFile",               link = "Question" },
  { group = "NvimTreeSpecialFile",             link = "Title" },
  { group = "NvimTreeSymlink",                 link = "Underlined" },

  -- Folder Text
  { group = "NvimTreeRootFolder",              link = "Title" },
  { group = "NvimTreeFolderName",              link = "Directory" },
  { group = "NvimTreeEmptyFolderName",         link = "Directory" },
  { group = "NvimTreeOpenedFolderName",        link = "Directory" },
  { group = "NvimTreeSymlinkFolderName",       link = "Directory" },

  -- File Icons
  { group = "NvimTreeFileIcon",                link = "NvimTreeNormal" },
  { group = "NvimTreeSymlinkIcon",             link = "NvimTreeNormal" },

  -- Folder Icons
  { group = "NvimTreeFolderIcon",              def = "guifg=#8094b4 ctermfg=Blue" },
  { group = "NvimTreeOpenedFolderIcon",        link = "NvimTreeFolderIcon" },
  { group = "NvimTreeClosedFolderIcon",        link = "NvimTreeFolderIcon" },
  { group = "NvimTreeFolderArrowClosed",       link = "NvimTreeIndentMarker" },
  { group = "NvimTreeFolderArrowOpen",         link = "NvimTreeIndentMarker" },

  -- Indent
  { group = "NvimTreeIndentMarker",            link = "NvimTreeFolderIcon" },

  -- Picker
  { group = "NvimTreeWindowPicker",            def = "guifg=#ededed guibg=#4493c8 gui=bold ctermfg=White ctermbg=DarkBlue" },

  -- LiveFilter
  { group = "NvimTreeLiveFilterPrefix",        link = "PreProc" },
  { group = "NvimTreeLiveFilterValue",         link = "ModeMsg" },

  -- Clipboard
  { group = "NvimTreeCutHL",                   link = "SpellBad" },
  { group = "NvimTreeCopiedHL",                link = "SpellRare" },

  -- Bookmark
  { group = "NvimTreeBookmarkIcon",            link = "NvimTreeFolderIcon" },
  { group = "NvimTreeBookmarkHL",              link = "SpellLocal" },

  -- Modified
  { group = "NvimTreeModifiedIcon",            link = "Type" },
  { group = "NvimTreeModifiedFileHL",          link = "NvimTreeModifiedIcon" },
  { group = "NvimTreeModifiedFolderHL",        link = "NvimTreeModifiedFileHL" },

  -- Hidden
  { group = "NvimTreeHiddenIcon",              link = "Conceal" },
  { group = "NvimTreeHiddenFileHL",            link = "NvimTreeHiddenIcon" },
  { group = "NvimTreeHiddenFolderHL",          link = "NvimTreeHiddenFileHL" },

  -- Hidden Display
  { group = "NvimTreeHiddenDisplay",           link = "Conceal" },

  -- Opened
  { group = "NvimTreeOpenedHL",                link = "Special" },

  -- Git Icon
  { group = "NvimTreeGitDeletedIcon",          link = "Statement" },
  { group = "NvimTreeGitDirtyIcon",            link = "Statement" },
  { group = "NvimTreeGitIgnoredIcon",          link = "Comment" },
  { group = "NvimTreeGitMergeIcon",            link = "Constant" },
  { group = "NvimTreeGitNewIcon",              link = "PreProc" },
  { group = "NvimTreeGitRenamedIcon",          link = "PreProc" },
  { group = "NvimTreeGitStagedIcon",           link = "Constant" },

  -- Git File Highlight
  { group = "NvimTreeGitFileDeletedHL",        link = "NvimTreeGitDeletedIcon" },
  { group = "NvimTreeGitFileDirtyHL",          link = "NvimTreeGitDirtyIcon" },
  { group = "NvimTreeGitFileIgnoredHL",        link = "NvimTreeGitIgnoredIcon" },
  { group = "NvimTreeGitFileMergeHL",          link = "NvimTreeGitMergeIcon" },
  { group = "NvimTreeGitFileNewHL",            link = "NvimTreeGitNewIcon" },
  { group = "NvimTreeGitFileRenamedHL",        link = "NvimTreeGitRenamedIcon" },
  { group = "NvimTreeGitFileStagedHL",         link = "NvimTreeGitStagedIcon" },

  -- Git Folder Highlight
  { group = "NvimTreeGitFolderDeletedHL",      link = "NvimTreeGitFileDeletedHL" },
  { group = "NvimTreeGitFolderDirtyHL",        link = "NvimTreeGitFileDirtyHL" },
  { group = "NvimTreeGitFolderIgnoredHL",      link = "NvimTreeGitFileIgnoredHL" },
  { group = "NvimTreeGitFolderMergeHL",        link = "NvimTreeGitFileMergeHL" },
  { group = "NvimTreeGitFolderNewHL",          link = "NvimTreeGitFileNewHL" },
  { group = "NvimTreeGitFolderRenamedHL",      link = "NvimTreeGitFileRenamedHL" },
  { group = "NvimTreeGitFolderStagedHL",       link = "NvimTreeGitFileStagedHL" },

  -- Diagnostics Icon
  { group = "NvimTreeDiagnosticErrorIcon",     link = "DiagnosticError" },
  { group = "NvimTreeDiagnosticWarnIcon",      link = "DiagnosticWarn" },
  { group = "NvimTreeDiagnosticInfoIcon",      link = "DiagnosticInfo" },
  { group = "NvimTreeDiagnosticHintIcon",      link = "DiagnosticHint" },

  -- Diagnostics File Highlight
  { group = "NvimTreeDiagnosticErrorFileHL",   link = "DiagnosticUnderlineError" },
  { group = "NvimTreeDiagnosticWarnFileHL",    link = "DiagnosticUnderlineWarn" },
  { group = "NvimTreeDiagnosticInfoFileHL",    link = "DiagnosticUnderlineInfo" },
  { group = "NvimTreeDiagnosticHintFileHL",    link = "DiagnosticUnderlineHint" },

  -- Diagnostics Folder Highlight
  { group = "NvimTreeDiagnosticErrorFolderHL", link = "NvimTreeDiagnosticErrorFileHL" },
  { group = "NvimTreeDiagnosticWarnFolderHL",  link = "NvimTreeDiagnosticWarnFileHL" },
  { group = "NvimTreeDiagnosticInfoFolderHL",  link = "NvimTreeDiagnosticInfoFileHL" },
  { group = "NvimTreeDiagnosticHintFolderHL",  link = "NvimTreeDiagnosticHintFileHL" },
}

-- nvim-tree highlight groups to legacy
M.LEGACY_LINKS = {
  NvimTreeModifiedIcon = "NvimTreeModifiedFile",

  NvimTreeOpenedHL = "NvimTreeOpenedFile",

  NvimTreeBookmarkIcon = "NvimTreeBookmark",

  NvimTreeGitDeletedIcon = "NvimTreeGitDeleted",
  NvimTreeGitDirtyIcon = "NvimTreeGitDirty",
  NvimTreeGitIgnoredIcon = "NvimTreeGitIgnored",
  NvimTreeGitMergeIcon = "NvimTreeGitMerge",
  NvimTreeGitNewIcon = "NvimTreeGitNew",
  NvimTreeGitRenamedIcon = "NvimTreeGitRenamed",
  NvimTreeGitStagedIcon = "NvimTreeGitStaged",

  NvimTreeGitFileDeletedHL = "NvimTreeFileDeleted",
  NvimTreeGitFileDirtyHL = "NvimTreeFileDirty",
  NvimTreeGitFileIgnoredHL = "NvimTreeFileIgnored",
  NvimTreeGitFileMergeHL = "NvimTreeFileMerge",
  NvimTreeGitFileNewHL = "NvimTreeFileNew",
  NvimTreeGitFileRenamedHL = "NvimTreeFileRenamed",
  NvimTreeGitFileStagedHL = "NvimTreeFileStaged",

  NvimTreeGitFolderDeletedHL = "NvimTreeFolderDeleted",
  NvimTreeGitFolderDirtyHL = "NvimTreeFolderDirty",
  NvimTreeGitFolderIgnoredHL = "NvimTreeFolderIgnored",
  NvimTreeGitFolderMergeHL = "NvimTreeFolderMerge",
  NvimTreeGitFolderNewHL = "NvimTreeFolderNew",
  NvimTreeGitFolderRenamedHL = "NvimTreeFolderRenamed",
  NvimTreeGitFolderStagedHL = "NvimTreeFolderStaged",

  NvimTreeDiagnosticErrorIcon = "NvimTreeLspDiagnosticsError",
  NvimTreeDiagnosticWarnIcon = "NvimTreeLspDiagnosticsWarning",
  NvimTreeDiagnosticInfoIcon = "NvimTreeLspDiagnosticsInformation",
  NvimTreeDiagnosticHintIcon = "NvimTreeLspDiagnosticsHint",

  NvimTreeDiagnosticErrorFileHL = "NvimTreeLspDiagnosticsErrorText",
  NvimTreeDiagnosticWarnFileHL = "NvimTreeLspDiagnosticsWarningText",
  NvimTreeDiagnosticInfoFileHL = "NvimTreeLspDiagnosticsInformationText",
  NvimTreeDiagnosticHintFileHL = "NvimTreeLspDiagnosticsHintText",

  NvimTreeDiagnosticErrorFolderHL = "NvimTreeLspDiagnosticsErrorFolderText",
  NvimTreeDiagnosticWarnFolderHL = "NvimTreeLspDiagnosticsWarningFolderText",
  NvimTreeDiagnosticInfoFolderHL = "NvimTreeLspDiagnosticsInformationFolderText",
  NvimTreeDiagnosticHintFolderHL = "NvimTreeLspDiagnosticsHintFolderText",
}

local function highlight_main()
  -- non-linked
  for _, g in ipairs(M.HIGHLIGHT_GROUPS) do
    if g.def then
      vim.api.nvim_command("hi def " .. g.group .. " " .. g.def)
    end
  end

  -- hard link override when legacy only is present
  for from, to in pairs(M.LEGACY_LINKS) do
    local hl_from = vim.api.nvim_get_hl(0, { name = from })
    local hl_to = vim.api.nvim_get_hl(0, { name = to })
    if vim.tbl_isempty(hl_from) and not vim.tbl_isempty(hl_to) then
      vim.api.nvim_command("hi link " .. from .. " " .. to)
    end
  end

  -- default links
  for _, g in ipairs(M.HIGHLIGHT_GROUPS) do
    if g.link then
      vim.api.nvim_command("hi def link " .. g.group .. " " .. g.link)
    end
  end
end

---Create all NvimTree* highlight groups with just a unique foreground colour
---NvimTreeCursorLine has just a background colour
---Add a CL variant for each group with the same background colour as NvimTreeCursorLine
---This is done here, as redefining groups in the test context is a performance issue, due to the number of :help ui-event-hl_attr_define events
local function highlight_functest()
  -- arbitrary cursor line "unique" value: math.random(tonumber('0x707070'),tonumber('0x909090'))
  local hex_bg = "#85a450"

  -- unique colour for each group, descending from #fefefe
  local i, r, g, b = 1, 254, 254, 254
  local rgb_fg, hex_fg

  -- build the cursor line first, background only
  local hgs = vim.tbl_filter(function(hg)
    if hg.group == "NvimTreeCursorLine" then
      vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { bg = hex_bg })
      return false
    else
      return true
    end
  end, M.HIGHLIGHT_GROUPS)

  -- define the remainder with unique foregrounds
  for _, hg in ipairs(hgs) do
    -- next unique fg colour
    rgb_fg = r * 256 * 256 + g * 256 + b
    hex_fg = string.format("#%x", rgb_fg)
    i = i + 1
    if (i % 256 == 0) then
      b, g, r = 254, 254, r - 1
    elseif (i % 16 == 0) then
      b, g = 254, g - 1
    else
      b = b - 1
    end

    -- add the group's concrete definition with fg only
    vim.api.nvim_set_hl(0, hg.group, { fg = hex_fg })

    -- create an NvimTreeCursorLine variant
    vim.api.nvim_set_hl(0, hg.group .. "CL", { fg = hex_fg, bg = hex_bg })
  end
end

---Create all highlight groups and links. Idempotent.
function M.highlight()
  if NVT_FUNCTEST_CONTEXT then ---@diagnostic disable-line: undefined-global
    highlight_functest()
  else
    highlight_main()
  end
end

return M
