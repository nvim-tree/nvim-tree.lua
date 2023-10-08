local M = {}

-- nvim-tree default highlight group links
local DEFAULT_LINKS = {
  -- File Text
  NvimTreeFolderName = "Directory",
  NvimTreeEmptyFolderName = "Directory",
  NvimTreeOpenedFolderName = "Directory",
  NvimTreeSymlinkFolderName = "Directory",

  -- Folder Text
  NvimTreeOpenedFileIcon = "NvimTreeOpenedFile",
  NvimTreeOpenedFolderIcon = "NvimTreeFolderIcon",
  NvimTreeClosedFolderIcon = "NvimTreeFolderIcon",

  -- Standard
  NvimTreeNormal = "Normal",
  NvimTreeNormalFloat = "NormalFloat",
  NvimTreeNormalNC = "NvimTreeNormal",
  NvimTreeLineNr = "LineNr",
  NvimTreeWinSeparator = "WinSeparator",
  NvimTreeEndOfBuffer = "EndOfBuffer",
  NvimTreePopup = "Normal",
  NvimTreeSignColumn = "NvimTreeNormal",
  NvimTreeCursorLine = "CursorLine",
  NvimTreeCursorColumn = "CursorColumn",
  NvimTreeCursorLineNr = "CursorLineNr",
  NvimTreeStatusLine = "StatusLine",
  NvimTreeStatusLineNC = "StatusLineNC",

  -- Clipboard
  NvimTreeCutHL = "SpellBad",
  NvimTreeCopiedHL = "SpellRare",

  -- Bookmark Highlight
  NvimTreeBookmarkHL = "SpellLocal",

  -- Git Icon
  NvimTreeGitIgnored = "Comment",

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

local function get_color_from_hl(hl_name, fallback)
  local id = vim.api.nvim_get_hl_id_by_name(hl_name)
  if not id then
    return fallback
  end

  -- TODO this is unreachable as nvim_get_hl_id_by_name returns a new ID if not present
  local foreground = vim.fn.synIDattr(vim.fn.synIDtrans(id), "fg")
  if not foreground or foreground == "" then
    return fallback
  end

  return foreground
end

local function get_colors()
  return {
    red = vim.g.terminal_color_1 or get_color_from_hl("Keyword", "Red"),
    green = vim.g.terminal_color_2 or get_color_from_hl("Character", "Green"),
    yellow = vim.g.terminal_color_3 or get_color_from_hl("PreProc", "Yellow"),
    blue = vim.g.terminal_color_4 or get_color_from_hl("Include", "Blue"),
    purple = vim.g.terminal_color_5 or get_color_from_hl("Define", "Purple"),
    cyan = vim.g.terminal_color_6 or get_color_from_hl("Conditional", "Cyan"),
    dark_red = vim.g.terminal_color_9 or get_color_from_hl("Keyword", "DarkRed"),
    orange = vim.g.terminal_color_11 or get_color_from_hl("Number", "Orange"),
  }
end

local function get_hl_groups()
  local colors = get_colors()

  return {
    IndentMarker = { fg = "#8094b4" },
    Symlink = { gui = "bold", fg = colors.cyan },
    FolderIcon = { fg = "#8094b4" },
    RootFolder = { fg = colors.purple },

    ExecFile = { gui = "bold", fg = colors.green },
    SpecialFile = { gui = "bold,underline", fg = colors.yellow },
    ImageFile = { gui = "bold", fg = colors.purple },
    OpenedFile = { gui = "bold", fg = colors.green },
    ModifiedFile = { fg = colors.green },

    GitDirty = { fg = colors.dark_red },
    GitDeleted = { fg = colors.dark_red },
    GitStaged = { fg = colors.green },
    GitMerge = { fg = colors.orange },
    GitRenamed = { fg = colors.purple },
    GitNew = { fg = colors.yellow },

    WindowPicker = { gui = "bold", fg = "#ededed", bg = "#4493c8" },
    LiveFilterPrefix = { gui = "bold", fg = colors.purple },
    LiveFilterValue = { gui = "bold", fg = "#fff" },

    Bookmark = { fg = colors.green },
  }
end

function M.setup()
  local highlight_groups = get_hl_groups()
  for k, d in pairs(highlight_groups) do
    local gui = d.gui and " gui=" .. d.gui or ""
    local fg = d.fg and " guifg=" .. d.fg or ""
    local bg = d.bg and " guibg=" .. d.bg or ""
    vim.api.nvim_command("hi def NvimTree" .. k .. gui .. fg .. bg)
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
