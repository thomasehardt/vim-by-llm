" Run with: vim -E -s -u <vimrc> -S tests/check-mappings.vim
" Writes results to $VIM_MGR_TEST_OUT and exits non-zero on any failure.
let s:out = []
let s:failed = 0

function! s:check(mode, lhs, expected) abort
  let l:rhs = maparg(a:lhs, a:mode)
  if l:rhs =~# a:expected
    call add(s:out, printf('✓ %s %-14s -> %s', a:mode, a:lhs, a:expected))
  else
    call add(s:out, printf('✗ %s %-14s expected %s, got "%s"', a:mode, a:lhs, a:expected, l:rhs))
    let s:failed = 1
  endif
endfunction

function! s:check_true(desc, value) abort
  call add(s:out, (a:value ? '✓ ' : '✗ ') . a:desc)
  if !a:value | let s:failed = 1 | endif
endfunction

call s:check('n', '<Space><Bar>', 'vsplit')
call s:check('n', '<Space>-', 'split')
call s:check('n', '<C-H>', '<C-W>h')
call s:check('n', '<Space>z', 'vim_mgr#zoom')
call s:check('n', '<Space>f', 'vim_mgr#find_files')
call s:check('n', '<Space>b', 'Buffers')
call s:check('n', '<Space>s', 'Rg')
call s:check('n', '<Space>e', 'NERDTreeToggle')
call s:check('n', '<Space>g', 'vim_mgr#git_status')
call s:check('n', '<Space>G', 'lazygit')
call s:check('n', '<Space>\', 'vim_mgr#scratch_toggle')
call s:check('n', '<Space>B', 'monitor_cmd')
call s:check('n', '<Space>m', 'vim_mgr#menu')
call s:check('n', '<Space>?', 'vim_mgr#cheatsheet')
call s:check('n', '<Space>r', 'vim_mgr#reload')
call s:check('n', '<Space>a', ':Ask')
call s:check('x', '<Space>a', 'vim_mgr#ask_visual')
call s:check('n', '<Space>y', 'vim_mgr#yank_op')
call s:check('x', '<Space>y', 'vim_mgr#yank_op')
call s:check('t', '<C-Q>', 'vim_mgr#terminal_ctrl_q')

call s:check_true('commands :Ask :Cheatsheet :Scratch :VimMgrMenu exist',
      \ exists(':Ask') == 2 && exists(':Cheatsheet') == 2 && exists(':Scratch') == 2 && exists(':VimMgrMenu') == 2)
call s:check_true('autoload functions load', !empty(vim_mgr#monitor_cmd()) && exists('*vim_mgr#llm_cmd'))
call s:check_true('a colorscheme is active', exists('g:colors_name'))
call s:check_true('no errors while loading the vimrc', empty(v:errmsg))
if !empty(v:errmsg)
  call add(s:out, '  last error: ' . v:errmsg)
endif

call writefile(s:out, $VIM_MGR_TEST_OUT)
execute s:failed ? 'cquit' : 'qall!'
