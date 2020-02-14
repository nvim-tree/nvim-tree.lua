if exists('g:loaded_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link LuaTreePopup Normal
hi def LuaTreeEndOfBuffer guifg=bg

execute 'hi def LuaTreeFolderName guifg='.g:terminal_color_4.' gui=bold'
execute 'hi def LuaTreeFolderIcon guifg='.g:terminal_color_11

execute 'hi def LuaTreeLicenseFile guifg='.g:terminal_color_3
execute 'hi def LuaTreeMarkdownFile guifg='.g:terminal_color_5
execute 'hi def LuaTreeImageFile guifg='.g:terminal_color_5
execute 'hi def LuaTreeYamlFile guifg='.g:terminal_color_3
execute 'hi def LuaTreeTomlFile guifg='.g:terminal_color_3
execute 'hi def LuaTreeGitignoreFile guifg='.g:terminal_color_3
execute 'hi def LuaTreeJsonFile guifg='.g:terminal_color_3

hi def LuaTreeLuaFile guifg=#2947b1
execute 'hi def LuaTreePythonFile guifg='.g:terminal_color_2
execute 'hi def LuaTreeShellFile guifg='.g:terminal_color_2
execute 'hi def LuaTreeJavascriptFile guifg='.g:terminal_color_3
execute 'hi def LuaTreeCFile guifg='.g:terminal_color_4
execute 'hi def LuaTreeReactFile guifg='.g:terminal_color_14
execute 'hi def LuaTreeHtmlFile guifg='.g:terminal_color_11
execute 'hi def LuaTreeRustFile guifg='.g:terminal_color_11
execute 'hi def LuaTreeVimFile guifg='.g:terminal_color_10
execute 'hi def LuaTreeTypescriptFile guifg='.g:terminal_color_12

command! LuaTree lua require'tree'.toggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tree = 1
