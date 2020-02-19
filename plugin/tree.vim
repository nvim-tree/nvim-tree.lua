if exists('g:loaded_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

hi def link LuaTreePopup Normal

au BufWritePost * lua require'tree'.refresh()
au BufEnter * lua require'tree'.check_windows_and_close()
au VimEnter * lua require'tree'.check_buffer_and_open()

command! LuaTree lua require'tree'.toggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tree = 1
