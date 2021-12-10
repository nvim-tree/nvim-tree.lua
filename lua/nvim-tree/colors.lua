local api = vim.api
local config = require'nvim-tree.config'

local M = {}

local function get_color_from_hl(hl_name, fallback)
  local id = vim.api.nvim_get_hl_id_by_name(hl_name)
  if not id then return fallback end

  local foreground = vim.fn.synIDattr(id, "fg")
  if not foreground or foreground == "" then return fallback end

  return foreground
end

local function get_colors()
  return {
    red      = '#fb4934',
    green    = '#b8bb26',
    yellow   = '#fabd2f',
    blue     = '#83a598',
    purple   = '#d3869b',
    cyan     = '#8ec07c',
    dark_red = '#cc241d',
    orange   = '#fe8019',
  }
end

local function get_hl_groups()
  local colors = get_colors()

  return {
    IndentMarker = { fg = '#d65d0e' },
    Symlink = { gui = 'bold', fg = colors.cyan },
    FolderIcon = { fg = '#d65d0e' },
    RootFolder = { fg = colors.purple },

    ExecFile = { gui = 'bold', fg = colors.green },
    SpecialFile = { gui = 'bold,underline', fg = colors.yellow },
    ImageFile = { gui = 'bold', fg = colors.purple },
    OpenedFile = { gui = 'bold', fg = colors.green },

    GitDirty = { fg = colors.dark_red },
    GitDeleted = { fg = colors.dark_red },
    GitStaged = { fg = colors.green },
    GitMerge = { fg = colors.orange },
    GitRenamed = { fg = colors.purple },
    GitNew = { fg = colors.yellow },

    WindowPicker = { gui = "bold", fg = "#ebdbb2", bg = "#458588" },
  }
end

local function get_links()
  return {
    FolderName = 'GruvboxAqua',
    EmptyFolderName = 'GruvboxGray',
    OpenedFolderName = 'GruvboxAqua',
    Normal = 'Normal',
    NormalNC = 'NvimTreeNormal',
    EndOfBuffer = 'EndOfBuffer',
    CursorLine = 'CursorLine',
    VertSplit = 'VertSplit',
    CursorColumn = 'CursorColumn',
    FileDirty = 'NvimTreeGitDirty',
    FileNew = 'NvimTreeGitNew',
    FileRenamed = 'NvimTreeGitRenamed',
    FileMerge = 'NvimTreeGitMerge',
    FileStaged = 'NvimTreeGitStaged',
    FileDeleted = 'NvimTreeGitDeleted',
    Popup = 'Normal',
    GitIgnored = 'GruvboxGray',
    StatusLine = "StatusLine",
    StatusLineNC = "StatusLineNC",
    SignColumn = 'NvimTreeNormal',
  }
end

function M.setup()
  if config.get_icon_state().show_file_icon and config.get_icon_state().has_devicons then
    require'nvim-web-devicons'.setup()
  end
  local higlight_groups = get_hl_groups()
  for k, d in pairs(higlight_groups) do
    local gui = d.gui and ' gui='..d.gui or ''
    local fg = d.fg and ' guifg='..d.fg or ''
    local bg = d.bg and ' guibg='..d.bg or ''
    api.nvim_command('hi def NvimTree'..k..gui..fg..bg)
  end

  local links = get_links()
  for k, d in pairs(links) do
    api.nvim_command('hi def link NvimTree'..k..' '..d)
  end
end

return M
