" ==============================================================================
" vim-mgr helpers: popups, menu, cheatsheet, clipboard, LLM ask.
" Loaded lazily the first time a vim_mgr#... function is called.
" ==============================================================================

let s:root = get(g:, 'vim_mgr_root', fnamemodify(resolve(expand('<sfile>:p')), ':h:h'))
let s:border = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']

function! s:warn(msg) abort
  echohl WarningMsg | echomsg 'vim-mgr: ' . a:msg | echohl None
endfunction

function! s:size(wfrac, hfrac) abort
  return [float2nr(&columns * a:wfrac), float2nr(&lines * a:hfrac)]
endfunction

" ------------------------------------------------------------------------------
" Windows and buffers
" ------------------------------------------------------------------------------

" Toggle a zoomed view of the current split by opening it in its own tab.
function! vim_mgr#zoom() abort
  if exists('t:vim_mgr_zoomed')
    tabclose
  elseif winnr('$') > 1
    tab split
    let t:vim_mgr_zoomed = 1
  endif
endfunction

" Delete the buffer but keep the window layout.
function! vim_mgr#close_buffer() abort
  if &modified
    call s:warn('buffer has unsaved changes')
    return
  endif
  let l:buf = bufnr('%')
  if len(getbufinfo({'buflisted': 1})) > 1
    bprevious
  else
    enew
  endif
  execute 'silent! bdelete ' . l:buf
endfunction

" ------------------------------------------------------------------------------
" Clipboard
" ------------------------------------------------------------------------------

" Copy text to the system clipboard: the + register when Vim can reach it,
" otherwise scripts/clipboard.sh. Over SSH also emit OSC 52 so the local
" terminal (or tmux with set-clipboard on) receives it.
function! vim_mgr#copy(text) abort
  if has('clipboard_working')
    call setreg('+', a:text)
  else
    call system(s:root . '/scripts/clipboard.sh', a:text)
  endif
  if !empty($SSH_TTY) && exists('*echoraw') && exists('*base64_encode') && exists('*str2blob')
    call echoraw("\e]52;c;" . base64_encode(str2blob(split(a:text, "\n", 1))) . "\x07")
  endif
  let l:lines = len(split(a:text, "\n"))
  echo printf('copied %d line%s to clipboard', l:lines, l:lines == 1 ? '' : 's')
endfunction

function! vim_mgr#yank_lines(first, last) abort
  call vim_mgr#copy(join(getline(a:first, a:last), "\n") . "\n")
endfunction

" Works as an operatorfunc (<leader>y{motion}) and from visual mode.
function! vim_mgr#yank_op(type) abort
  let l:saved = [getreg('"'), getregtype('"')]
  try
    if a:type ==# 'line' || a:type ==# 'V'
      let l:cmd = a:type ==# 'line' ? "'[V']y" : 'gvy'
    elseif a:type ==# 'char'
      let l:cmd = '`[v`]y'
    else
      let l:cmd = 'gvy'
    endif
    silent execute 'normal! ' . l:cmd
    call vim_mgr#copy(getreg('"'))
  finally
    call setreg('"', l:saved[0], l:saved[1])
  endtry
endfunction

" ------------------------------------------------------------------------------
" Finding and git
" ------------------------------------------------------------------------------

function! s:in_git_repo() abort
  call system('git rev-parse --is-inside-work-tree')
  return v:shell_error == 0
endfunction

function! vim_mgr#find_files() abort
  if !exists(':Files')
    call s:warn('fzf.vim is not installed (run: vim-mgr plugins)')
    return
  endif
  " In a repo, list tracked + untracked files but skip ignored ones.
  if s:in_git_repo()
    GFiles --cached --others --exclude-standard
  else
    Files
  endif
endfunction

function! vim_mgr#git_status() abort
  if exists(':Git') == 2
    Git
  else
    call vim_mgr#popup_term('git status; echo; git log --oneline -10; read -r -p "press enter"', 'git')
  endif
endfunction

function! vim_mgr#monitor_cmd() abort
  for l:cmd in ['btm', 'htop', 'top']
    if executable(l:cmd)
      return l:cmd
    endif
  endfor
  return 'top'
endfunction

" ------------------------------------------------------------------------------
" Popup terminals
" ------------------------------------------------------------------------------

function! s:open_term_popup(buf, title, wfrac, hfrac) abort
  let [l:w, l:h] = s:size(a:wfrac, a:hfrac)
  return popup_create(a:buf, {
        \ 'title': ' ' . a:title . ' ',
        \ 'minwidth': l:w, 'maxwidth': l:w, 'minheight': l:h, 'maxheight': l:h,
        \ 'border': [], 'borderchars': s:border,
        \ 'borderhighlight': ['VimMgrBorder'],
        \ })
endfunction

" Run a shell command in a floating terminal that closes when it exits.
function! vim_mgr#popup_term(cmd, title) abort
  " A bare program name gets a friendly check; shell snippets are run as-is.
  if a:cmd =~# '^\S\+$' && !executable(a:cmd)
    call s:warn(a:cmd . ' is not installed')
    return
  endif
  let l:argv = [&shell, &shellcmdflag, a:cmd]
  if !has('popupwin') || !has('terminal')
    execute 'tab terminal ++close ' . join(map(l:argv, 'escape(v:val, " ")'))
    return
  endif
  let l:buf = term_start(l:argv, {'hidden': 1, 'term_finish': 'close', 'cwd': getcwd()})
  call s:open_term_popup(l:buf, a:title, 0.9, 0.85)
endfunction

" A persistent scratch shell: toggling hides the popup but keeps the shell
" (and whatever is running in it) alive, like the tmux scratch popup.
let s:scratch = {'buf': -1, 'popup': -1}

function! s:scratch_visible() abort
  return s:scratch.popup > 0 && index(popup_list(), s:scratch.popup) >= 0
endfunction

function! vim_mgr#scratch_toggle() abort
  if !has('popupwin') || !has('terminal')
    call s:warn('scratch shell needs Vim with +popupwin and +terminal')
    return
  endif
  if s:scratch_visible()
    call popup_close(s:scratch.popup)
    return
  endif
  if !bufexists(s:scratch.buf) || term_getstatus(s:scratch.buf) !~# 'running'
    let s:scratch.buf = term_start([&shell], {
          \ 'hidden': 1, 'term_finish': 'close', 'cwd': getcwd(), 'term_name': 'scratch'})
  endif
  let s:scratch.popup = s:open_term_popup(s:scratch.buf, 'scratch  (Ctrl-q hides)', 0.8, 0.75)
endfunction

" Terminal-mode Ctrl-q: hide the scratch popup, pass the key through elsewhere.
function! vim_mgr#terminal_ctrl_q() abort
  if s:scratch_visible() && bufnr('%') == s:scratch.buf
    call popup_close(s:scratch.popup)
  else
    call term_sendkeys(bufnr('%'), "\<C-q>")
  endif
endfunction

" ------------------------------------------------------------------------------
" Actions menu
" ------------------------------------------------------------------------------

" [key, label, command]. An empty entry draws a separator.
let s:menu = [
      \ ['?', 'Help / cheatsheet',  'call vim_mgr#cheatsheet()'],
      \ [],
      \ ['f', 'Find file',          'call vim_mgr#find_files()'],
      \ ['b', 'Switch buffer',      'Buffers'],
      \ ['s', 'Search project (rg)', 'Rg'],
      \ ['o', 'Recent files',       'History'],
      \ ['e', 'File tree',          'NERDTreeToggle'],
      \ [],
      \ ['\', 'Scratch shell',      'call vim_mgr#scratch_toggle()'],
      \ ['g', 'Git status',         'call vim_mgr#git_status()'],
      \ ['G', 'lazygit',            "call vim_mgr#popup_term('lazygit', 'lazygit')"],
      \ ['B', 'System monitor',     "call vim_mgr#popup_term(vim_mgr#monitor_cmd(), 'system monitor')"],
      \ ['a', 'Ask the LLM',        'call feedkeys(":Ask ", "n")'],
      \ [],
      \ ['z', 'Zoom split',         'call vim_mgr#zoom()'],
      \ ['n', 'Toggle relative numbers', 'set relativenumber!'],
      \ ['w', 'Toggle wrap',        'set wrap!'],
      \ ['S', 'Toggle spell',       'set spell!'],
      \ [],
      \ ['P', 'Update plugins',     'PlugUpdate'],
      \ ['r', 'Reload config',      'call vim_mgr#reload()'],
      \ ['x', 'Close buffer',       'call vim_mgr#close_buffer()'],
      \ ]

function! s:menu_filter(id, key) abort
  for l:i in range(len(s:menu))
    if !empty(s:menu[l:i]) && s:menu[l:i][0] ==# a:key
      call popup_close(a:id, l:i + 1)
      return 1
    endif
  endfor
  return popup_filter_menu(a:id, a:key)
endfunction

function! s:menu_run(id, result) abort
  if a:result < 1 || empty(s:menu[a:result - 1])
    return
  endif
  execute s:menu[a:result - 1][2]
endfunction

function! vim_mgr#menu() abort
  let l:lines = map(copy(s:menu), {_, v -> empty(v) ? repeat('─', 30) : printf(' %-2s %s', v[0], v[1])})
  if !has('popupwin')
    let l:choice = inputlist(['vim actions:'] + map(copy(l:lines), {i, v -> (i + 1) . '.' . v}))
    call s:menu_run(0, l:choice)
    return
  endif
  call popup_menu(l:lines, {
        \ 'title': ' vim actions ',
        \ 'borderchars': s:border,
        \ 'borderhighlight': ['VimMgrBorder'],
        \ 'filter': function('s:menu_filter'),
        \ 'callback': function('s:menu_run'),
        \ })
endfunction

" ------------------------------------------------------------------------------
" Cheatsheet
" ------------------------------------------------------------------------------

function! s:cheatsheet_filter(id, key) abort
  let l:scroll = {'j': "\<C-e>", 'k': "\<C-y>", "\<Down>": "\<C-e>", "\<Up>": "\<C-y>",
        \ "\<C-d>": "\<C-d>", "\<C-u>": "\<C-u>", 'd': "\<C-d>", 'u': "\<C-u>",
        \ 'g': 'gg', 'G': 'G', "\<Space>": "\<C-f>", "\<C-f>": "\<C-f>", "\<C-b>": "\<C-b>"}
  if has_key(l:scroll, a:key)
    call win_execute(a:id, 'normal! ' . l:scroll[a:key])
    return 1
  endif
  if index(['q', "\<Esc>", '?'], a:key) >= 0
    call popup_close(a:id)
    return 1
  endif
  return 1   " swallow everything else so keys don't leak into the buffer
endfunction

function! vim_mgr#cheatsheet() abort
  let l:file = s:root . '/cheatsheet.md'
  if !filereadable(l:file)
    call s:warn('no cheatsheet at ' . l:file)
    return
  endif
  if !has('popupwin')
    execute 'botright split ' . fnameescape(l:file)
    setlocal readonly nomodifiable
    return
  endif
  let [l:w, l:h] = s:size(0.8, 0.8)
  let l:id = popup_create(readfile(l:file), {
        \ 'title': ' cheatsheet  (j/k scroll, q closes) ',
        \ 'minwidth': l:w, 'maxwidth': l:w, 'minheight': l:h, 'maxheight': l:h,
        \ 'border': [], 'borderchars': s:border, 'borderhighlight': ['VimMgrBorder'],
        \ 'padding': [0, 1, 0, 1], 'scrollbar': 1, 'mapping': 0,
        \ 'filter': function('s:cheatsheet_filter'),
        \ })
  call win_execute(l:id, 'setlocal filetype=markdown conceallevel=2 nowrap')
endfunction

" ------------------------------------------------------------------------------
" Reload
" ------------------------------------------------------------------------------

function! vim_mgr#reload() abort
  source $MYVIMRC
  if exists('*lightline#enable')
    call lightline#enable()
  endif
  echo 'vimrc reloaded'
endfunction

" ------------------------------------------------------------------------------
" Ask an LLM
" ------------------------------------------------------------------------------
" Configure in ~/.vimrc.local:
"   let g:vim_mgr_llm_cmd = 'ollama run qwen3:8b'
"   let g:vim_mgr_llm_prompt_template = 'You are a Vim expert. {{query}}'
" or with the VIM_MGR_LLM_CMD / VIM_MGR_LLM_PROMPT_TEMPLATE environment
" variables (these are what 'vim-mgr ask' reads too).

function! vim_mgr#llm_cmd() abort
  let l:cmd = get(g:, 'vim_mgr_llm_cmd', $VIM_MGR_LLM_CMD)
  if !empty(l:cmd)
    return l:cmd
  endif
  for [l:bin, l:full] in [['claude', 'claude -p'], ['agy', 'agy -p']]
    if executable(l:bin)
      return l:full
    endif
  endfor
  return ''
endfunction

function! s:prompt(query, context) abort
  let l:default = 'Answer this question about Vim briefly and accurately: {{query}}'
  let l:template = get(g:, 'vim_mgr_llm_prompt_template',
        \ empty($VIM_MGR_LLM_PROMPT_TEMPLATE) ? l:default : $VIM_MGR_LLM_PROMPT_TEMPLATE)
  let l:prompt = substitute(l:template, '{{query}}', escape(a:query, '\&'), 'g')
  if !empty(a:context)
    let l:prompt .= "\n\nContext (" . (empty(&filetype) ? 'text' : &filetype) . "):\n```\n" . a:context . "\n```"
  endif
  return l:prompt
endfunction

function! s:ask_buffer(query) abort
  let l:win = bufwinnr('^\[Ask\]$')
  if l:win > 0
    execute l:win . 'wincmd w'
    silent %delete _
  else
    botright 15new
    silent file [Ask]
    setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted filetype=markdown wrap linebreak
    nnoremap <buffer> <silent> q :close<CR>
  endif
  call setline(1, ['# ' . a:query, ''])
  return bufnr('%')
endfunction

function! vim_mgr#ask(query, ...) abort
  let l:context = a:0 ? a:1 : ''
  if empty(a:query)
    call s:warn('usage: :Ask <question>')
    return
  endif
  let l:cmd = vim_mgr#llm_cmd()
  if empty(l:cmd)
    call s:warn('no LLM CLI found; set g:vim_mgr_llm_cmd or $VIM_MGR_LLM_CMD')
    return
  endif
  let l:prompt = s:prompt(a:query, l:context)
  let l:src_ft = &filetype
  let l:buf = s:ask_buffer(a:query)
  call appendbufline(l:buf, '$', '_asking ' . l:cmd . '..._')
  " eval lets the command contain arguments (e.g. 'ollama run llama3'); the
  " prompt stays inside a quoted variable so it is never re-parsed by the shell.
  let s:ask_job = job_start(['/bin/sh', '-c', 'eval "$VIM_MGR_LLM_CMD" ''"$VIM_MGR_PROMPT"'''], {
        \ 'env': {'VIM_MGR_LLM_CMD': l:cmd, 'VIM_MGR_PROMPT': l:prompt},
        \ 'in_io': 'null',
        \ 'out_io': 'buffer', 'out_buf': l:buf, 'out_modifiable': 1,
        \ 'err_io': 'out',
        \ 'exit_cb': {_, status -> appendbufline(l:buf, '$',
        \     status == 0 ? ['', '── done ──'] : ['', '── exited with status ' . status . ' ──'])},
        \ })
  wincmd p
endfunction

function! vim_mgr#ask_visual() abort
  let l:saved = [getreg('"'), getregtype('"')]
  silent normal! gvy
  let l:selection = getreg('"')
  call setreg('"', l:saved[0], l:saved[1])
  let l:query = input('Ask about selection: ')
  redraw
  call vim_mgr#ask(l:query, l:selection)
endfunction
