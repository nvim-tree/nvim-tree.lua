local api = vim.api

local M = {}

local function get_color_from_hl(hl_name, fallback)
  local id = vim.api.nvim_get_hl_id_by_name(hl_name)
  if not id then return fallback end

  local hl = vim.api.nvim_get_hl_by_id(id, true)
  if not hl or not hl.foreground then return fallback end

  return hl.foreground
end

local function get_colors()
  return {
    red      = vim.g.terminal_color_1  or get_color_from_hl('Keyword', 'Red'),
    green    = vim.g.terminal_color_2  or get_color_from_hl('Character', 'Green'),
    yellow   = vim.g.terminal_color_3  or get_color_from_hl('PreProc', 'Yellow'),
    blue     = vim.g.terminal_color_4  or get_color_from_hl('Include', 'Blue'),
    purple   = vim.g.terminal_color_5  or get_color_from_hl('Define', 'Purple'),
    cyan     = vim.g.terminal_color_6  or get_color_from_hl('Conditional', 'Cyan'),
    dark_red = vim.g.terminal_color_9  or get_color_from_hl('Keyword', 'DarkRed'),
    orange   = vim.g.terminal_color_11 or get_color_from_hl('Number', 'Orange'),
  }
end

local function get_hl_groups()
  local colors = get_colors()

  return {
    IndentMarker = { fg = '#90a4ae' },
    Symlink = { gui = 'bold', fg = colors.cyan },
    FolderIcon = { fg = '#90a4ae' },

    ExecFile = { gui = 'bold', fg = colors.green },
    SpecialFile = { gui = 'bold,underline', fg = colors.yellow },
    ImageFile = { gui = 'bold', fg = colors.purple },

    GitDirty = { fg = colors.dark_red },
    GitStaged = { fg = colors.green },
    GitMerge = { fg = colors.orange },
    GitRenamed = { fg = colors.purple },
    GitNew = { fg = colors.yellow },

    -- TODO: remove those when we add this to nvim-web-devicons
    MarkdownIcon = { fg = colors.purple },
    LicenseIcon = { fg = colors.yellow },
    YamlIcon = { fg = colors.yellow },
    TomlIcon = { fg = colors.yellow },
    GitignoreIcon = { fg = colors.yellow },
    JsonIcon = { fg = colors.yellow },
    LuaIcon = { fg = '#42a5f5' },
    GoIcon = { fg = '#7Fd5EA' },
    PythonIcon = { fg = colors.green },
    ShellIcon = { fg = colors.green },
    JavascriptIcon = { fg = colors.yellow },
    CIcon = { fg = colors.blue },
    ReactIcon = { fg = colors.cyan },
    HtmlIcon = { fg = colors.orange },
    RustIcon = { fg = colors.orange },
    VimIcon = { fg = colors.green },
    TypescriptIcon = { fg = colors.blue },
  }
end

-- TODO: remove those when we add this to nvim-web-devicons
M.hl_groups = {
  ['LICENSE'] = 'LicenseIcon';
  ['license'] = 'LicenseIcon';
  ['vim'] = 'VimIcon';
  ['.vimrc'] = 'VimIcon';
  ['c'] = 'CIcon';
  ['cpp'] = 'CIcon';
  ['python'] = 'PythonIcon';
  ['lua'] = 'LuaIcon';
  ['rs'] = 'RustIcon';
  ['sh'] = 'ShellIcon';
  ['csh'] = 'ShellIcon';
  ['zsh'] = 'ShellIcon';
  ['bash'] = 'ShellIcon';
  ['md'] = 'MarkdownIcon';
  ['json'] = 'JsonIcon';
  ['toml'] = 'TomlIcon';
  ['go'] = 'GoIcon';
  ['yaml'] = 'YamlIcon';
  ['yml'] = 'YamlIcon';
  ['conf'] = 'GitignoreIcon';
  ['javascript'] = 'JavascriptIcon';
  ['typescript'] = 'TypescriptIcon';
  ['jsx'] = 'ReactIcon';
  ['tsx'] = 'ReactIcon';
  ['htm'] = 'HtmlIcon';
  ['html'] = 'HtmlIcon';
  ['slim'] = 'HtmlIcon';
  ['haml'] = 'HtmlIcon';
  ['ejs'] = 'HtmlIcon';
}

local function get_links()
  return {
    FolderName = 'Directory',
    Normal = 'Normal',
    EndOfBuffer = 'EndOfBuffer',
    CursorLine = 'CursorLine',
    VertSplit = 'VertSplit',
    CursorColumn = 'CursorColumn',
    FileDirty = 'LuaTreeGitDirty',
    FileNew = 'LuaTreeGitNew',
    FileRenamed = 'LuaTreeGitRenamed',
    FileMerge = 'LuaTreeGitMerge',
    FileStaged = 'LuaTreeGitStaged',
  }
end

function M.setup()
  local higlight_groups = get_hl_groups()
  for k, d in pairs(higlight_groups) do
    local gui = d.gui or 'NONE'
    api.nvim_command('hi def LuaTree'..k..' gui='..gui..' guifg='..d.fg)
  end

  local links = get_links()
  for k, d in pairs(links) do
    api.nvim_command('hi def link LuaTree'..k..' '..d)
  end
end

return M
