if exists('g:loaded_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1 " Disable netrw

hi def link LuaTreePopup Normal
hi def LuaTreeEndOfBuffer guifg=bg

if exists('g:terminal_color_0')
    let s:bg = g:terminal_color_0
    let s:fg = g:terminal_color_7 

    let s:red = g:terminal_color_1 
    let s:green = g:terminal_color_2 
    let s:yellow = g:terminal_color_3 
    let s:blue = g:terminal_color_4 
    let s:purple = g:terminal_color_5 
    let s:cyan = g:terminal_color_6 
    let s:orange = g:terminal_color_11

    let s:dark_red = g:terminal_color_9 
    let s:visual_grey = g:terminal_color_8 
    let s:comment_grey = g:terminal_color_15
    let s:luacolor = '#2947b1'

    execute 'hi def LuaTreeFolderName gui=bold guifg='.s:blue
    execute 'hi def LuaTreeFolderIcon guifg='.s:orange

    execute 'hi def LuaTreeExecFile gui=bold guifg='.s:green
    execute 'hi def LuaTreeSpecialFile gui=bold,underline guifg='.s:yellow
    execute 'hi def LuaTreeImageFile gui=bold guifg='.s:purple

    execute 'hi def LuaTreeMarkdownFile guifg='.s:purple
    execute 'hi def LuaTreeLicenseFile guifg='.s:yellow
    execute 'hi def LuaTreeYamlFile guifg='.s:yellow
    execute 'hi def LuaTreeTomlFile guifg='.s:yellow
    execute 'hi def LuaTreeGitignoreFile guifg='.s:yellow
    execute 'hi def LuaTreeJsonFile guifg='.s:yellow

    execute 'hi def LuaTreeLuaFile guifg='s:luacolor
    execute 'hi def LuaTreePythonFile guifg='.s:green
    execute 'hi def LuaTreeShellFile guifg='.s:green
    execute 'hi def LuaTreeJavascriptFile guifg='.s:yellow
    execute 'hi def LuaTreeCFile guifg='.s:blue
    execute 'hi def LuaTreeReactFile guifg='.s:cyan
    execute 'hi def LuaTreeHtmlFile guifg='.s:orange
    execute 'hi def LuaTreeRustFile guifg='.s:orange
    execute 'hi def LuaTreeVimFile guifg='.s:green
    execute 'hi def LuaTreeTypescriptFile guifg='.s:blue

    execute 'hi def LuaTreeGitDirty guifg='.s:dark_red
    execute 'hi def LuaTreeGitStaged guifg='.s:green
    execute 'hi def LuaTreeGitMerge guifg='.s:orange
    execute 'hi def LuaTreeGitRenamed guifg='.s:purple
    execute 'hi def LuaTreeGitNew guifg='.s:yellow
endif

au BufWritePost * lua require'tree'.refresh()

command! LuaTree lua require'tree'.toggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tree = 1
