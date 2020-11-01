local a = vim.api

local function get_color_from_hl(hl_name, fallback)
  local id = a.nvim_get_hl_id_by_name(hl_name)
  if not id then return fallback end

  local hl = a.nvim_get_hl_by_id(id, true)
  if not hl or not hl.foreground then return fallback end

  return hl.foreground
end

local function get_colors()
  return {
    red      = vim.g.terminal_color_1  or get_color_from_hl('Keyword',     '#a02030'),
    green    = vim.g.terminal_color_2  or get_color_from_hl('Character',   '#20a033'),
    yellow   = vim.g.terminal_color_3  or get_color_from_hl('PreProc',     '#aca040'),
    blue     = vim.g.terminal_color_4  or get_color_from_hl('Include',     '#4030d0'),
    purple   = vim.g.terminal_color_5  or get_color_from_hl('Define',      '#8040d0'),
    cyan     = vim.g.terminal_color_6  or get_color_from_hl('Conditional', '#74dfdb'),
    dark_red = vim.g.terminal_color_9  or get_color_from_hl('Keyword',     '#701920'),
    orange   = vim.g.terminal_color_11 or get_color_from_hl('Number',      '#cc8c22'),
  }
end

local function get_hl_groups()
  local colors = get_colors()

  return {
    IndentMarker = { fg = '#8094b4' },
    Symlink = { gui = 'bold', fg = colors.cyan },
    FolderIcon = { fg = '#8094b4' },
    RootFolder = { fg = colors.purple },

    ExecFile = { gui = 'bold', fg = colors.green },
    SpecialFile = { gui = 'bold,underline', fg = colors.yellow },
    ImageFile = { gui = 'bold', fg = colors.purple },

    GitDirty = { fg = colors.dark_red },
    GitDeleted = { fg = colors.dark_red },
    GitStaged = { fg = colors.green },
    GitMerge = { fg = colors.orange },
    GitRenamed = { fg = colors.purple },
    GitNew = { fg = colors.yellow }
  }
end

local function get_links()
  return {
    FolderName = 'Directory',
    Normal = 'Normal',
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
  }
end

local opts = nil

return {
  configure = function(o)
    opts = o
  end,
  setup = function()
    if opts and opts.web_devicons.show == true then
      if not require'nvim-web-devicons'.has_loaded() then
        require'nvim-web-devicons'.setup({ default = opts.web_devicons.default })
      end
    end

    local higlight_groups = get_hl_groups()
    for k, d in pairs(higlight_groups) do
      local gui = d.gui or 'NONE'
      vim.cmd('hi def NvimTree'..k..' gui='..gui..' guifg='..d.fg)
    end

    local links = get_links()
    for k, d in pairs(links) do
      vim.cmd('hi def link NvimTree'..k..' '..d)
    end
  end
}
