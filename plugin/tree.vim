if has('win32') || exists('g:loaded_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

hi def link LuaTreePopup Normal

augroup LuaTree
  au BufWritePost * lua require'tree'.refresh()

  if get(g:, 'lua_tree_auto_close') != 0
    au BufEnter * lua require'tree'.check_windows_and_close()
  endif

  if get(g:, 'lua_tree_auto_open') != 0
    au VimEnter * lua require'tree'.check_buffer_and_open()
  endif

  if get(g:, 'lua_tree_follow') != 0
    au BufEnter * :LuaTreeFindFile
  endif

  au BufEnter * lua require'tree'.navigate_to_buffer_dir()
  au ColorScheme * lua require'tree'.reset_highlight()
augroup end

" TODO: WinEnter is not the right autocommand for this task,
" but we do not have LayoutChange or WinMove kind of option atm,
" so this is deactivated by default to avoid messing up users workflows

" au WinEnter * lua require'tree'.replace_tree()

command! LuaTreeToggle lua require'tree'.toggle()
command! LuaTreeRefresh lua require'tree'.refresh()
command! LuaTreeFindFile lua require'tree'.find()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tree = 1
