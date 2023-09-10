local M = {}

local function get_color_from_hl(hl_name, fallback)
  local id = vim.api.nvim_get_hl_id_by_name(hl_name)
  if not id then
    return fallback
  end

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

    CopiedText = { gui = "underdotted" },
    CutText = { gui = "strikethrough" },

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
    BookmarkText = { gui = "underdashed" }
  }
end

local function get_links()
  return {
    FolderName = "Directory",
    EmptyFolderName = "Directory",
    OpenedFolderName = "Directory",
    SymlinkFolderName = "Directory",
    OpenedFolderIcon = "NvimTreeFolderIcon",
    ClosedFolderIcon = "NvimTreeFolderIcon",
    OpenedFileIcon = "NvimTreeOpenedFile",
    Normal = "Normal",
    NormalFloat = "NormalFloat",
    NormalNC = "NvimTreeNormal",
    EndOfBuffer = "EndOfBuffer",
    CursorLineNr = "CursorLineNr",
    LineNr = "LineNr",
    CursorLine = "CursorLine",
    WinSeparator = "WinSeparator",
    CursorColumn = "CursorColumn",
    FileDirty = "NvimTreeGitDirty",
    FileNew = "NvimTreeGitNew",
    FileRenamed = "NvimTreeGitRenamed",
    FileMerge = "NvimTreeGitMerge",
    FileStaged = "NvimTreeGitStaged",
    FileDeleted = "NvimTreeGitDeleted",
    FileIgnored = "NvimTreeGitIgnored",
    FolderDirty = "NvimTreeFileDirty",
    FolderNew = "NvimTreeFileNew",
    FolderRenamed = "NvimTreeFileRenamed",
    FolderMerge = "NvimTreeFileMerge",
    FolderStaged = "NvimTreeFileStaged",
    FolderDeleted = "NvimTreeFileDeleted",
    FolderIgnored = "NvimTreeFileIgnored",
    LspDiagnosticsError = "DiagnosticError",
    LspDiagnosticsWarning = "DiagnosticWarn",
    LspDiagnosticsInformation = "DiagnosticInfo",
    LspDiagnosticsHint = "DiagnosticHint",
    LspDiagnosticsErrorText = "NvimTreeLspDiagnosticsError",
    LspDiagnosticsWarningText = "NvimTreeLspDiagnosticsWarning",
    LspDiagnosticsInformationText = "NvimTreeLspDiagnosticsInformation",
    LspDiagnosticsHintText = "NvimTreeLspDiagnosticsHintFile",
    LspDiagnosticsErrorFolderText = "NvimTreeLspDiagnosticsErrorText",
    LspDiagnosticsWarningFolderText = "NvimTreeLspDiagnosticsWarningText",
    LspDiagnosticsInformationFolderText = "NvimTreeLspDiagnosticsInformationText",
    LspDiagnosticsHintFolderText = "NvimTreeLspDiagnosticsHintFileText",
    Popup = "Normal",
    GitIgnored = "Comment",
    StatusLine = "StatusLine",
    StatusLineNC = "StatusLineNC",
    SignColumn = "NvimTreeNormal",
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

  local links = get_links()
  for k, d in pairs(links) do
    vim.api.nvim_command("hi def link NvimTree" .. k .. " " .. d)
  end
end

return M
