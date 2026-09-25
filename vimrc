" ==============================================================================
" vim-by-llm: vimrc
" ==============================================================================
" Managed by vim-mgr. This file is symlinked to ~/.vimrc and is overwritten by
" 'vim-mgr update'. Put machine-specific tweaks in ~/.vimrc.local instead.
"
" Layout of this repo (resolved through the ~/.vimrc symlink):
"   vimrc              this file
"   plugin/, autoload/ vim-mgr helpers (menu, cheatsheet, popups, ask)
"   scripts/           shell helpers (clipboard)
"   cheatsheet.md      shown by <leader>?
"
" Conventions deliberately mirror tmux-by-antigravity so muscle memory carries
" across: | and - split, h/j/k/l move, z zooms, \ opens a scratch shell,
" g/G for git, m for an actions menu, ? for the cheatsheet.
" ==============================================================================

set nocompatible
set encoding=utf-8
scriptencoding utf-8

" Where this repo lives, even when loaded through the ~/.vimrc symlink.
let g:vim_mgr_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
" Add the repo itself to runtimepath so its plugin/ and autoload/ load.
execute 'set runtimepath^=' . fnameescape(g:vim_mgr_root)
execute 'set runtimepath+=' . fnameescape(g:vim_mgr_root . '/after')

" Space as leader: the biggest key, reachable from both hands.
let mapleader = ' '
let maplocalleader = ','

" ------------------------------------------------------------------------------
" Plugins (vim-plug)
" ------------------------------------------------------------------------------
" vim-plug lives in ~/.vim/autoload/plug.vim and plugins in ~/.vim/plugged.
" 'vim-mgr install' fetches vim-plug; if it's missing we skip the whole block
" so a fresh or offline machine still gets a working (plain) editor.
let g:vim_mgr_has_plug = filereadable(expand('~/.vim/autoload/plug.vim'))

if g:vim_mgr_has_plug
  call plug#begin('~/.vim/plugged')

  " Look and feel
  Plug 'catppuccin/vim', { 'as': 'catppuccin' }   " same palette as the tmux bar
  Plug 'romainl/vim-dichromatic'                  " colorblind-friendly alternative
  Plug 'itchyny/lightline.vim'                    " light statusline

  " Finding things
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'preservim/nerdtree'

  " Git
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'

  " Editing
  Plug 'tpope/vim-commentary'                     " gcc / gc{motion}
  Plug 'tpope/vim-surround'                       " cs"' ds( ysiw]
  Plug 'tpope/vim-repeat'                         " . works with the above
  Plug 'tpope/vim-sleuth'                         " detect indent per file
  Plug 'godlygeek/tabular'                        " :Tabularize /=
  Plug 'tmsvg/pear-tree'                          " auto-close brackets and quotes

  " Formatting
  Plug 'countravioli/prettyxml.vim'               " :PrettyXML
  Plug 'vim-scripts/jdaddy.vim'                   " gqaj formats the JSON under the cursor

  " Extra plugins for this machine only: put Plug lines in this file.
  if filereadable(expand('~/.vimrc.plugins.local'))
    source ~/.vimrc.plugins.local
  endif

  call plug#end()   " also runs: filetype plugin indent on | syntax enable
else
  filetype plugin indent on
  syntax enable
endif

" ------------------------------------------------------------------------------
" General behaviour
" ------------------------------------------------------------------------------
set hidden                      " switch buffers without saving first
set backspace=indent,eol,start
set history=1000
set updatetime=300              " faster gitgutter / CursorHold
set timeoutlen=600 ttimeoutlen=20
set mouse=a
if !has('nvim') && exists('&ttymouse')
  set ttymouse=sgr              " mouse works past column 223 and inside tmux
endif
set nomodeline modelines=0      " modelines have a long history of CVEs
set autoread                    " pick up changes made outside Vim

" Swap, undo and backup files all go under ~/.vim/tmp instead of next to files.
" Persistent undo means 'u' still works after closing and reopening a file.
for s:dir in ['swap', 'undo', 'backup']
  let s:path = expand('~/.vim/tmp/' . s:dir)
  if !isdirectory(s:path)
    call mkdir(s:path, 'p', 0700)
  endif
endfor
set directory=~/.vim/tmp/swap//
set undodir=~/.vim/tmp/undo//
set backupdir=~/.vim/tmp/backup//
set undofile

" ------------------------------------------------------------------------------
" Display
" ------------------------------------------------------------------------------
set number relativenumber       " absolute on the cursor line, relative elsewhere
set ruler showcmd
set laststatus=2 noshowmode     " lightline shows the mode
set signcolumn=yes              " gitgutter doesn't shift text left and right
set scrolloff=15 sidescrolloff=5
set nowrap
set cursorline
set splitright splitbelow       " new splits open where you'd expect
set tabpagemax=100              " vim -p *.py can open more than 10 tabs
set wildmenu wildmode=longest:full,full
set wildignore+=*.o,*.pyc,*/.git/*,*/node_modules/*
set list listchars=tab:»\ ,trail:·,nbsp:␣
set shortmess+=c
set belloff=all

" 24-bit colour, including inside tmux.
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit' || !empty($TMUX))
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" Undercurl for spelling/LSP diagnostics (the tmux config passes these through).
let &t_Cs = "\e[4:3m"
let &t_Ce = "\e[4:0m"

" Cursor shape: bar in insert, underline in replace, block in normal.
let &t_SI = "\e[6 q"
let &t_SR = "\e[4 q"
let &t_EI = "\e[2 q"

" ------------------------------------------------------------------------------
" Indentation and search
" ------------------------------------------------------------------------------
set expandtab tabstop=4 shiftwidth=4 softtabstop=4 smartindent
set incsearch hlsearch ignorecase smartcase

if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case grepformat=%f:%l:%c:%m
endif

augroup vim_mgr_filetypes
  autocmd!
  autocmd FileType markdown,text setlocal wrap linebreak spell
  autocmd FileType yaml,json,javascript,typescript,typescriptreact,html,css,lua setlocal ts=2 sw=2 sts=2 et
  autocmd FileType make setlocal noexpandtab
  autocmd FileType gitcommit setlocal spell textwidth=72
augroup END

augroup vim_mgr_general
  autocmd!
  " Reopen files at the last cursor position.
  autocmd BufReadPost * if line("'\"") >= 1 && line("'\"") <= line('$') && &ft !~# 'commit'
        \ | execute "normal! g`\"" | endif
  " Check for outside changes when coming back to Vim.
  autocmd FocusGained,BufEnter * if mode() !=# 'c' | checktime | endif
  " Keep splits even when the terminal is resized.
  autocmd VimResized * wincmd =
augroup END

" ------------------------------------------------------------------------------
" Colours
" ------------------------------------------------------------------------------
" Override in ~/.vimrc.local with: let g:vim_mgr_colorscheme = 'dichromatic'
let g:vim_mgr_colorscheme = get(g:, 'vim_mgr_colorscheme', 'catppuccin_mocha')
set background=dark

function! s:apply_colorscheme() abort
  try
    execute 'colorscheme ' . g:vim_mgr_colorscheme
  catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme habamax         " built-in fallback before plugins are installed
  endtry
endfunction

let g:lightline = {
      \ 'colorscheme': 'catppuccin_mocha',
      \ 'active': {
      \   'left':  [['mode', 'paste'], ['gitbranch', 'readonly', 'filename', 'modified']],
      \   'right': [['lineinfo'], ['percent'], ['filetype', 'fileencoding']],
      \ },
      \ 'component_function': { 'gitbranch': 'FugitiveHead' },
      \ }

" ------------------------------------------------------------------------------
" Keybindings
" ------------------------------------------------------------------------------
" Full list: <leader>? (cheatsheet) or <leader>m (actions menu).

" Clear search highlight (./ kept from the old vimrc).
nnoremap <silent> ./ :nohlsearch<CR>
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Quick save / quit.
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>

" Splits: same keys as tmux (prefix | and prefix -).
nnoremap <silent> <leader><Bar> :vsplit<CR>
nnoremap <silent> <leader>- :split<CR>

" Move between splits with Ctrl-h/j/k/l (tmux uses prefix h/j/k/l).
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize splits with the arrow keys.
nnoremap <silent> <Up>    :resize +2<CR>
nnoremap <silent> <Down>  :resize -2<CR>
nnoremap <silent> <Left>  :vertical resize -4<CR>
nnoremap <silent> <Right> :vertical resize +4<CR>

" Zoom the current split (toggle), like tmux prefix z.
nnoremap <silent> <leader>z :call vim_mgr#zoom()<CR>

" Buffers: Shift-Left/Right like tmux windows, <leader><Tab> for the last one.
nnoremap <silent> <S-Left>  :bprevious<CR>
nnoremap <silent> <S-Right> :bnext<CR>
nnoremap <silent> <leader><Tab> :buffer #<CR>
nnoremap <silent> <leader>x :call vim_mgr#close_buffer()<CR>

" Keep the selection when indenting in visual mode.
vnoremap < <gv
vnoremap > >gv

" Move selected lines up/down.
vnoremap J :move '>+1<CR>gv=gv
vnoremap K :move '<-2<CR>gv=gv

" Insert the current filename (without extension), e.g. for class names.
inoremap \fn <C-R>=expand("%:t:r")<CR>

" Y yanks to end of line, like D and C.
nnoremap Y y$

" System clipboard. With +clipboard this uses the "+ register; otherwise it
" pipes through scripts/clipboard.sh and OSC 52, the same way the tmux config
" copies, so it works over SSH too.
nnoremap <silent> <leader>y :set operatorfunc=vim_mgr#yank_op<CR>g@
nnoremap <silent> <leader>yy :call vim_mgr#yank_lines(line('.'), line('.'))<CR>
xnoremap <silent> <leader>y :<C-u>call vim_mgr#yank_op(visualmode())<CR>
nnoremap <leader>p "+p
nnoremap <leader>P "+P

" Finding (fzf.vim).
nnoremap <silent> <leader>f :call vim_mgr#find_files()<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>s :Rg<CR>
nnoremap <silent> <leader>o :History<CR>
nnoremap <silent> <leader>l :BLines<CR>
nnoremap <silent> <leader>: :Commands<CR>

" File tree.
nnoremap <silent> <leader>e :NERDTreeToggle<CR>
nnoremap <silent> <leader>E :NERDTreeFind<CR>
let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeIgnore = ['\.git$', '\.DS_Store$', 'node_modules']

" Git.
nnoremap <silent> <leader>g :call vim_mgr#git_status()<CR>
nnoremap <silent> <leader>G :call vim_mgr#popup_term('lazygit', 'lazygit')<CR>
nnoremap <silent> ]h :GitGutterNextHunk<CR>
nnoremap <silent> [h :GitGutterPrevHunk<CR>
nnoremap <silent> <leader>ha :GitGutterStageHunk<CR>
nnoremap <silent> <leader>hu :GitGutterUndoHunk<CR>
nnoremap <silent> <leader>hp :GitGutterPreviewHunk<CR>
let g:gitgutter_map_keys = 0

" Popups (float over your work, vanish on exit).
nnoremap <silent> <leader><Bslash> :call vim_mgr#scratch_toggle()<CR>
nnoremap <silent> <leader>B :call vim_mgr#popup_term(vim_mgr#monitor_cmd(), 'system monitor')<CR>

" LLM: ask a question; in visual mode the selection is sent along as context.
nnoremap <leader>a :Ask<Space>
xnoremap <silent> <leader>a :<C-u>call vim_mgr#ask_visual()<CR>

" Menus, help, reload.
nnoremap <silent> <leader>m :call vim_mgr#menu()<CR>
nnoremap <silent> <leader>? :call vim_mgr#cheatsheet()<CR>
nnoremap <silent> <leader>r :call vim_mgr#reload()<CR>

" Toggles.
nnoremap <silent> <leader>tn :set relativenumber!<CR>
nnoremap <silent> <leader>tw :set wrap!<CR>
nnoremap <silent> <leader>ts :set spell!<CR>
nnoremap <silent> <leader>tl :set list!<CR>

" Terminal mode: Esc Esc gets you back to normal mode.
tnoremap <Esc><Esc> <C-\><C-n>

" ------------------------------------------------------------------------------
" Local overrides
" ------------------------------------------------------------------------------
" Never touched by 'vim-mgr update'. See ~/.vimrc.local.example for ideas.
if filereadable(expand('~/.vimrc.local'))
  source ~/.vimrc.local
endif

call s:apply_colorscheme()
