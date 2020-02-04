if exists('g:loaded_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! LuaTree lua require'tree'.toggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tree = 1

