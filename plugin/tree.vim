if exists('g:loaded_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link LuaTreePopup Normal
hi def LuaTreeEndOfBuffer guifg=bg

command! LuaTree lua require'tree'.toggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tree = 1

