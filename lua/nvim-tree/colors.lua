local M = {}

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
  NvimTreeModifiedFile = "Constant",
  NvimTreeOpenedFile = "Constant",
  NvimTreeSpecialFile = "PreProc",
  NvimTreeSymlink = "Statement",

  -- Folder Text
  NvimTreeRootFolder = "PreProc",
  NvimTreeFolderName = "Directory",
  NvimTreeEmptyFolderName = "Directory",
  NvimTreeOpenedFolderName = "Directory",
  NvimTreeSymlinkFolderName = "Directory",

  -- Icon
  NvimTreeFileIcon = "NvimTreeNormal",
  NvimTreeSymlinkIcon = "NvimTreeNormal",
  NvimTreeOpenedFileIcon = "NvimTreeOpenedFile",
  NvimTreeOpenedFolderIcon = "NvimTreeFolderIcon",
  NvimTreeClosedFolderIcon = "NvimTreeFolderIcon",
  NvimTreeFolderArrowClosed = "NvimTreeIndentMarker",
  NvimTreeFolderArrowOpen = "NvimTreeIndentMarker",

  -- Indent
  NvimTreeIndentMarker = "NvimTreeFileIcon",

  -- Clipboard
  NvimTreeCutHL = "SpellBad",
  NvimTreeCopiedHL = "SpellRare",

  -- Bookmark Icon
  NvimTreeBookmark = "Constant",

  -- Bookmark Highlight
  NvimTreeBookmarkHL = "SpellLocal",

  -- LiveFilter
  NvimTreeLiveFilterPrefix = "PreProc",
  NvimTreeLiveFilterValue = "ModeMsg",

  -- Git Icon
  NvimTreeGitDeleted = "Statement",
  NvimTreeGitDirty = "Statement",
  NvimTreeGitIgnored = "Comment",
  NvimTreeGitMerge = "Constant",
  NvimTreeGitNew = "PreProc",
  NvimTreeGitRenamed = "PreProc",
  NvimTreeGitStaged = "Constant",

  -- Git File Text
  NvimTreeFileDirty = "NvimTreeGitDirty",
  NvimTreeFileStaged = "NvimTreeGitStaged",
  NvimTreeFileMerge = "NvimTreeGitMerge",
  NvimTreeFileRenamed = "NvimTreeGitRenamed",
  NvimTreeFileNew = "NvimTreeGitNew",
  NvimTreeFileDeleted = "NvimTreeGitDeleted",
  NvimTreeFileIgnored = "NvimTreeGitIgnored",

  -- Git Folder Text
  NvimTreeFolderDirty = "NvimTreeFileDirty",
  NvimTreeFolderStaged = "NvimTreeFileStaged",
  NvimTreeFolderMerge = "NvimTreeFileMerge",
  NvimTreeFolderRenamed = "NvimTreeFileRenamed",
  NvimTreeFolderNew = "NvimTreeFileNew",
  NvimTreeFolderDeleted = "NvimTreeFileDeleted",
  NvimTreeFolderIgnored = "NvimTreeFileIgnored",

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
  NvimTreeDiagnosticErrorFolderHL = "DiagnosticUnderlineError",
  NvimTreeDiagnosticWarnFolderHL = "DiagnosticUnderlineWarn",
  NvimTreeDiagnosticInfoFolderHL = "DiagnosticUnderlineInfo",
  NvimTreeDiagnosticHintFolderHL = "DiagnosticUnderlineHint",
}

-- nvim-tree highlight groups to legacy
local LEGACY_LINKS = {
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
    vim.api.nvim_command("hi " .. k .. " " .. d)
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
end

return M
