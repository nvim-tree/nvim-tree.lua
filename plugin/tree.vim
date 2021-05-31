if !has('nvim-0.5') || exists('g:loaded_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

if get(g:, 'nvim_tree_disable_netrw', 1) == 1
    let g:loaded_netrw = 1
    let g:loaded_netrwPlugin = 1
endif

augroup NvimTree
  if get(g:, 'nvim_tree_hijack_netrw', 1) == 1 && get(g:, 'nvim_tree_disable_netrw', 1) == 0
    silent! autocmd! FileExplorer *
  endif
  au BufWritePost * lua require'nvim-tree'.refresh()
  if get(g:, 'nvim_tree_lsp_diagnostics', 0) == 1
    au User LspDiagnosticsChanged lua require'nvim-tree.diagnostics'.update()
  endif
  au BufEnter * lua require'nvim-tree'.buf_enter()
  if get(g:, 'nvim_tree_auto_close') == 1
    au WinClosed * lua require'nvim-tree'.on_leave()
  endif
  au ColorScheme * lua require'nvim-tree'.reset_highlight()
  au User FugitiveChanged lua require'nvim-tree'.refresh()
  if get(g:, 'nvim_tree_tab_open') == 1
    au TabEnter * lua require'nvim-tree'.tab_change()
  endif
  au SessionLoadPost * lua require'nvim-tree.view'._wipe_rogue_buffer()
augroup end

command! NvimTreeOpen lua require'nvim-tree'.open()
command! NvimTreeClose lua require'nvim-tree'.close()
command! NvimTreeToggle lua require'nvim-tree'.toggle()
command! NvimTreeRefresh lua require'nvim-tree'.refresh()
command! NvimTreeClipboard lua require'nvim-tree'.print_clipboard()
command! NvimTreeFindFile lua require'nvim-tree'.find_file(true)

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tree = 1
