# vim cheatsheet

Leader is `Space`. Notation below: `<leader>f` means press Space, then f.
Keys mirror the tmux config where they can: `|` `-` split, `z` zoom, `\` scratch,
`g`/`G` git, `m` menu, `?` this sheet.

## Files and search

| Key | Action |
| --- | --- |
| `<leader>f` | Find file (git-aware fzf) |
| `<leader>b` | Switch buffer |
| `<leader>s` | Search the project with ripgrep |
| `<leader>o` | Recently opened files |
| `<leader>l` | Search lines in this buffer |
| `<leader>:` | Search commands |
| `<leader>e` / `<leader>E` | Toggle file tree / reveal current file in it |

## Splits and buffers

| Key | Action |
| --- | --- |
| `<leader>\|` | Split left/right |
| `<leader>-` | Split top/bottom |
| `Ctrl-h j k l` | Move to split left / down / up / right |
| Arrow keys | Resize the current split |
| `<leader>z` | Zoom split (toggle) |
| `Shift-Left` / `Shift-Right` | Previous / next buffer |
| `<leader>Tab` | Last buffer |
| `<leader>x` | Close buffer, keep the layout |
| `<leader>w` / `<leader>q` | Write / quit |

## Popups (float over your work, vanish on exit)

| Key | Action |
| --- | --- |
| `<leader>\` | Scratch shell (persistent; `Ctrl-q` hides it, the shell keeps running) |
| `<leader>G` | lazygit |
| `<leader>B` | System monitor (btm/htop/top) |
| `<leader>m` | Actions menu (press the letter or pick with j/k) |
| `<leader>?` | This cheatsheet |

## Git

| Key | Action |
| --- | --- |
| `<leader>g` | Git status (fugitive; `s` stage, `cc` commit, `=` diff) |
| `]h` / `[h` | Next / previous hunk |
| `<leader>ha` | Stage hunk |
| `<leader>hu` | Undo hunk |
| `<leader>hp` | Preview hunk |

## Editing

| Key | Action |
| --- | --- |
| `gcc` / `gc{motion}` | Comment line / motion |
| `cs"'` `ds(` `ysiw]` | Change / delete / add surroundings |
| `J` / `K` (visual) | Move selected lines down / up |
| `<` / `>` (visual) | Indent, keeping the selection |
| `Y` | Yank to end of line |
| `:Tabularize /=` | Align on a character |
| `\fn` (insert) | Insert the current filename, without extension |
| `( [ { " '` (insert) | Closing pair is added automatically (pear-tree) |
| `:PrettyXML` | Reformat the XML in this buffer |
| `gqaj` | Reformat the JSON object under the cursor (jdaddy) |

## Clipboard

| Key | Action |
| --- | --- |
| `<leader>y{motion}` | Copy to the system clipboard |
| `<leader>yy` | Copy the line to the system clipboard |
| `<leader>y` (visual) | Copy the selection to the system clipboard |
| `<leader>p` / `<leader>P` | Paste from the system clipboard after / before |

Copy works on macOS, Linux (Wayland/X11) and WSL, and over SSH via OSC 52.

## Ask an LLM

| Key | Action |
| --- | --- |
| `<leader>a` | `:Ask <question>` (answer streams into a split, `q` closes it) |
| `<leader>a` (visual) | Ask about the selected code |
| `:'<,'>AskRange <q>` | Same, from the command line |

Uses `claude -p` or `agy -p` if found. Set `g:vim_mgr_llm_cmd` in
`~/.vimrc.local` to use something else (e.g. `ollama run qwen3:8b`).

## Toggles

| Key | Action |
| --- | --- |
| `<leader>tn` | Relative line numbers |
| `<leader>tw` | Wrap |
| `<leader>ts` | Spell check |
| `<leader>tl` | Show whitespace |
| `./` or `Esc Esc` | Clear search highlight |
| `Esc Esc` (terminal) | Leave terminal mode |
| `<leader>r` | Reload config |

## Where things live

- Config: `~/.vimrc` (symlink into `~/.local/share/vim-mgr`)
- Your overrides: `~/.vimrc.local`, extra plugins: `~/.vimrc.plugins.local`
- Plugins: `~/.vim/plugged/`
- Swap, undo, backup: `~/.vim/tmp/`
- Backups of your pre-install config: `~/.vim-backup-<date>/`

*Run `vim-mgr help` for the command-line tool, and `:map` inside Vim for every mapping.*
