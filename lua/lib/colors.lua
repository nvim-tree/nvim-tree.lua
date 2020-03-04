local colors = require 'lib/config'.colors

local cmd = vim.api.nvim_command

local HIGHLIGHTS = {
    Symlink = { gui = 'bold', fg = colors.cyan },
    FolderName = { gui = 'bold', fg = colors.blue },
    FolderIcon = { fg = '#90a4ae' },

    ExecFile = { gui = 'bold', fg = colors.green },
    SpecialFile = { gui = 'bold,underline', fg = colors.yellow },
    ImageFile = { gui = 'bold', fg = colors.purple },
    MarkdownFile = { fg = colors.purple },
    LicenseFile = { fg = colors.yellow },
    YamlFile = { fg = colors.yellow },
    TomlFile = { fg = colors.yellow },
    GitignoreFile = { fg = colors.yellow },
    JsonFile = { fg = colors.yellow },

    LuaFile = { fg = '#42a5f5' },
    PythonFile = { fg = colors.green },
    ShellFile = { fg = colors.green },
    JavascriptFile = { fg = colors.yellow },
    CFile = { fg = colors.blue },
    ReactFile = { fg = colors.cyan },
    HtmlFile = { fg = colors.orange },
    RustFile = { fg = colors.orange },
    VimFile = { fg = colors.green },
    TypescriptFile = { fg = colors.blue },

    GitDirty = { fg = colors.dark_red },
    GitStaged = { fg = colors.green },
    GitMerge = { fg = colors.orange },
    GitRenamed = { fg = colors.purple },
    GitNew = { fg = colors.yellow },

    EndOfBuffer = { fg = 'bg' }
}

local function init_colors()
    for k, d in pairs(HIGHLIGHTS) do
        local gui = d.gui or 'NONE'
        vim.api.nvim_command('hi def LuaTree'..k..' gui='..gui..' guifg='..d.fg)
    end
end

return {
    init_colors = init_colors
}
