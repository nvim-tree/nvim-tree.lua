local M = {
  -- namespace for all tree window highlights
  NS_ID = vim.api.nvim_create_namespace "nvim_tree",
}

-- directly defined groups, please keep these to an absolute minimum
local DEFAULT_DEFS = {

  NvimTreeFolderIcon = "guifg=#8094b4 ctermfg=Blue",
  NvimTreeWindowPicker = "guifg=#ededed guibg=#4493c8 gui=bold ctermfg=White ctermbg=Cyan",
}

-- nvim-tree default highlight group links, please attempt to keep in order with help
local DEFAULT_LINKS = {

  -- Standard
  NvimTreeNormal = "Normal",
  NvimTreeNormalFloat = "NormalFloat",
  NvimTreeNormalNC = "NvimTreeNormal",

  NvimTreeLineNr = "LineNr",
  NvimTreeWinSeparator = "WinSeparator",
  NvimTreeEndOfBuffer = "EndOfBuffer",
  NvimTreePopup = "Normal",
  NvimTreeSignColumn = "NvimTreeNormal",

  NvimTreeCursorColumn = "CursorColumn",
  NvimTreeCursorLine = "CursorLine",
  NvimTreeCursorLineNr = "CursorLineNr",

  NvimTreeStatusLine = "StatusLine",
  NvimTreeStatusLineNC = "StatusLineNC",

  -- File Text
  NvimTreeExecFile = "Constant",
  NvimTreeImageFile = "PreProc",
  NvimTreeOpenedFile = "Constant",
  NvimTreeSpecialFile = "PreProc",
  NvimTreeSymlink = "Statement",

  -- Folder Text
  NvimTreeRootFolder = "PreProc",
  NvimTreeFolderName = "Directory",
  NvimTreeEmptyFolderName = "Directory",
  NvimTreeOpenedFolderName = "Directory",
  NvimTreeSymlinkFolderName = "Directory",

  -- File Icons
  NvimTreeFileIcon = "NvimTreeNormal",
  NvimTreeSymlinkIcon = "NvimTreeNormal",
  NvimTreeOpenedFileIcon = "NvimTreeOpenedFile",

  -- Folder Icons
  NvimTreeOpenedFolderIcon = "NvimTreeFolderIcon",
  NvimTreeClosedFolderIcon = "NvimTreeFolderIcon",
  NvimTreeFolderArrowClosed = "NvimTreeIndentMarker",
  NvimTreeFolderArrowOpen = "NvimTreeIndentMarker",

  -- Indent
  NvimTreeIndentMarker = "NvimTreeFileIcon",

  -- LiveFilter
  NvimTreeLiveFilterPrefix = "PreProc",
  NvimTreeLiveFilterValue = "ModeMsg",

  -- Clipboard
  NvimTreeCutHL = "SpellBad",
  NvimTreeCopiedHL = "SpellRare",

  -- Bookmark
  NvimTreeBookmarkIcon = "Constant",
  NvimTreeBookmarkHL = "SpellLocal",

  -- Modified
  NvimTreeModifiedIcon = "Constant",
  NvimTreeModifiedFileHL = "NvimTreeModifiedIcon",
  NvimTreeModifiedFolderHL = "NvimTreeModifiedFileHL",

  -- Opened
  NvimTreeOpenedHL = "Constant",

  -- Git Icon
  NvimTreeGitDeletedIcon = "Statement",
  NvimTreeGitDirtyIcon = "Statement",
  NvimTreeGitIgnoredIcon = "Comment",
  NvimTreeGitMergeIcon = "Constant",
  NvimTreeGitNewIcon = "PreProc",
  NvimTreeGitRenamedIcon = "PreProc",
  NvimTreeGitStagedIcon = "Constant",

  -- Git File Highlight
  NvimTreeGitFileDeletedHL = "NvimTreeGitDeletedIcon",
  NvimTreeGitFileDirtyHL = "NvimTreeGitDirtyIcon",
  NvimTreeGitFileIgnoredHL = "NvimTreeGitIgnoredIcon",
  NvimTreeGitFileMergeHL = "NvimTreeGitMergeIcon",
  NvimTreeGitFileNewHL = "NvimTreeGitNewIcon",
  NvimTreeGitFileRenamedHL = "NvimTreeGitRenamedIcon",
  NvimTreeGitFileStagedHL = "NvimTreeGitStagedIcon",

  -- Git Folder Highlight
  NvimTreeGitFolderDeletedHL = "NvimTreeGitFileDeletedHL",
  NvimTreeGitFolderDirtyHL = "NvimTreeGitFileDirtyHL",
  NvimTreeGitFolderIgnoredHL = "NvimTreeGitFileIgnoredHL",
  NvimTreeGitFolderMergeHL = "NvimTreeGitFileMergeHL",
  NvimTreeGitFolderNewHL = "NvimTreeGitFileNewHL",
  NvimTreeGitFolderRenamedHL = "NvimTreeGitFileRenamedHL",
  NvimTreeGitFolderStagedHL = "NvimTreeGitFileStagedHL",

  -- Diagnostics Icon
  NvimTreeDiagnosticErrorIcon = "DiagnosticError",
  NvimTreeDiagnosticWarnIcon = "DiagnosticWarn",
  NvimTreeDiagnosticInfoIcon = "DiagnosticInfo",
  NvimTreeDiagnosticHintIcon = "DiagnosticHint",

  -- Diagnostics File Highlight
  NvimTreeDiagnosticErrorFileHL = "DiagnosticUnderlineError",
  NvimTreeDiagnosticWarnFileHL = "DiagnosticUnderlineWarn",
  NvimTreeDiagnosticInfoFileHL = "DiagnosticUnderlineInfo",
  NvimTreeDiagnosticHintFileHL = "DiagnosticUnderlineHint",

  -- Diagnostics Folder Highlight
  NvimTreeDiagnosticErrorFolderHL = "NvimTreeDiagnosticErrorFileHL",
  NvimTreeDiagnosticWarnFolderHL = "NvimTreeDiagnosticWarnFileHL",
  NvimTreeDiagnosticInfoFolderHL = "NvimTreeDiagnosticInfoFileHL",
  NvimTreeDiagnosticHintFolderHL = "NvimTreeDiagnosticHintFileHL",
}

-- namespace standard links
local NS_LINKS = {
  EndOfBuffer = "NvimTreeEndOfBuffer",
  CursorLine = "NvimTreeCursorLine",
  CursorLineNr = "NvimTreeCursorLineNr",
  LineNr = "NvimTreeLineNr",
  WinSeparator = "NvimTreeWinSeparator",
  StatusLine = "NvimTreeStatusLine",
  StatusLineNC = "NvimTreeStatuslineNC",
  SignColumn = "NvimTreeSignColumn",
  Normal = "NvimTreeNormal",
  NormalNC = "NvimTreeNormalNC",
  NormalFloat = "NvimTreeNormalFloat",
}

-- nvim-tree highlight groups to legacy
local LEGACY_LINKS = {
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

function M.setup()
  -- non-linked
  for k, d in pairs(DEFAULT_DEFS) do
    vim.api.nvim_command("hi def " .. k .. " " .. d)
  end

  -- hard link override when legacy only is present
  for from, to in pairs(LEGACY_LINKS) do
    local hl_from = vim.api.nvim_get_hl(0, { name = from })
    local hl_to = vim.api.nvim_get_hl(0, { name = to })
    if vim.tbl_isempty(hl_from) and not vim.tbl_isempty(hl_to) then
      vim.api.nvim_command("hi link " .. from .. " " .. to)
    end
  end

  -- default links
  for from, to in pairs(DEFAULT_LINKS) do
    vim.api.nvim_command("hi def link " .. from .. " " .. to)
  end

  -- window standard; this doesn't appear to clear on ColorScheme however we err on the side of caution
  for from, to in pairs(NS_LINKS) do
    vim.api.nvim_set_hl(M.NS_ID, from, { link = to })
  end
end

return M
