" vim-mgr commands and highlight groups. Functions live in autoload/vim_mgr.vim.
if exists('g:loaded_vim_mgr')
  finish
endif
let g:loaded_vim_mgr = 1

command! -nargs=+ Ask call vim_mgr#ask(<q-args>)
command! -range -nargs=+ AskRange call vim_mgr#ask(<q-args>, join(getline(<line1>, <line2>), "\n"))
command! VimMgrMenu call vim_mgr#menu()
command! Cheatsheet call vim_mgr#cheatsheet()
command! Scratch call vim_mgr#scratch_toggle()
command! Zoom call vim_mgr#zoom()

" Ctrl-q inside the scratch popup hides it (the shell keeps running).
if has('terminal')
  tnoremap <silent> <C-q> <Cmd>call vim_mgr#terminal_ctrl_q()<CR>
endif

" Popup borders in the catppuccin blue used by the tmux status bar.
function! s:highlights() abort
  highlight default VimMgrBorder guifg=#89b4fa ctermfg=111
endfunction
call s:highlights()
augroup vim_mgr_highlights
  autocmd!
  autocmd ColorScheme * call s:highlights()
augroup END
