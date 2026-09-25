# Vim Configuration

This repository contains my personal Vim configuration, managed by a custom `vim-mgr` CLI tool. It's the Vim counterpart to [tmux-by-antigravity](https://github.com/thomasehardt/tmux-by-antigravity), and the keybindings match that config wherever they can.

## Installation

The easiest way to install this configuration is the bootstrap script. It clones the repository into a hidden directory (`~/.local/share/vim-mgr`), backs up your existing `~/.vimrc`, installs [vim-plug](https://github.com/junegunn/vim-plug) and the plugins, and installs the `vim-mgr` CLI tool.

```bash
curl -fsSL https://raw.githubusercontent.com/thomasehardt/vim-by-llm/main/install.sh | bash
```

Once it's installed, use the `vim-mgr` command to manage your setup:

- `vim-mgr update`: fetch the latest config from GitHub and install any new plugins.
- `vim-mgr edit`: open the `vimrc` in your editor (`vim-mgr edit local` opens `~/.vimrc.local`).
- `vim-mgr status`: check your installation.
- `vim-mgr doctor`: check which Vim features and optional tools are available.
- `vim-mgr plugins [install|update|clean]`: manage plugins without opening Vim.
- `vim-mgr cheatsheet`: show the keybinding cheatsheet.
- `vim-mgr ask <question>`: ask an LLM a Vim question.
- `vim-mgr restore`: put your backed-up `~/.vimrc` back.

Inside Vim, press `Space ?` for the cheatsheet or `Space m` for a menu of actions.

*Note: Make sure `~/.local/bin` is in your `$PATH`!*

### Requirements

- Vim 9 with `+popupwin`, `+terminal` and `+job` for popups, the scratch shell and `:Ask`. Older builds still get a working editor, with fallbacks.
- `git` and `curl`.
- Optional: `rg` (project search), `lazygit`, `btm` or `htop`, and `claude` or `agy` (for `:Ask`). `fzf` is downloaded automatically if it's missing.

### Local overrides

- `~/.vimrc.local` is sourced at the end of the vimrc and is never overwritten. `~/.vimrc.local.example` lists the available options.
- `~/.vimrc.plugins.local` holds extra `Plug '...'` lines for this machine only.

## Layout

```
vimrc                 the config (symlinked to ~/.vimrc)
plugin/vim_mgr.vim    commands (:Ask, :Cheatsheet, :Scratch, :VimMgrMenu)
autoload/vim_mgr.vim  popups, menu, clipboard, LLM integration
scripts/clipboard.sh  cross-platform copy to the system clipboard
cheatsheet.md         shown by Space ?
bin/vim-mgr           the management CLI
tests/                headless keybinding checks, plus a Docker install test
```

## Testing

```bash
bash tests/test-config.sh   # load the vimrc headlessly and check the keybindings
bash tests/run-tests.sh     # full install in a clean Ubuntu container (needs Docker)
```

## Documentation & Decision Log

To keep the configuration clean and understandable, all major additions, keybindings and plugins are documented here with the reasoning behind them. The `vimrc` itself also stays heavily commented.

### Decision Log

* **2026-09-25**:
  * **Decision**: Replaced the old Vundle-based `~/.vimrc` with a managed repo and a `vim-mgr` CLI, modelled on `tmux-mgr`.
  * **Reasoning**: One command installs or updates the same setup on any machine, and machine-specific changes live in `~/.vimrc.local` so updates never clobber them.

* **2026-09-25**:
  * **Decision**: Switched from Vundle to vim-plug.
  * **Reasoning**: Vundle is unmaintained. vim-plug installs in parallel, supports post-install hooks (used to fetch the `fzf` binary), and can run headless for `vim-mgr plugins`.

* **2026-09-25**:
  * **Decision**: Space is the leader, and the keys mirror the tmux config: `|` and `-` split, `z` zooms, `\` opens a scratch shell, `g`/`G` for git, `m` for a menu, `?` for the cheatsheet.
  * **Reasoning**: The same muscle memory works in both tools. Space is the easiest key to hit and doesn't do much in normal mode.

* **2026-09-25**:
  * **Decision**: Catppuccin Mocha colours, with vim-dichromatic installed as a colourblind-friendly alternative (`let g:vim_mgr_colorscheme = 'dichromatic'`).
  * **Reasoning**: Matches the tmux status bar. Dichromatic was the colorscheme in the previous vimrc, so it stays one line away.

* **2026-09-25**:
  * **Decision**: Popups (scratch shell, lazygit, system monitor, cheatsheet, actions menu) use Vim 9's native `popup_create` and `term_start`, with no plugin.
  * **Reasoning**: They float over your work like the tmux popups do. The scratch shell is hidden rather than killed (`Ctrl-q`), so long-running commands survive.

* **2026-09-25**:
  * **Decision**: `Space y` copies to the system clipboard through the `+` register when Vim can reach it, and otherwise through `scripts/clipboard.sh`. Over SSH it also emits OSC 52.
  * **Reasoning**: The Vim builds shipped by many distros lack `+clipboard`. This uses the same approach as the tmux config, so copying works on macOS, Wayland, X11, WSL and over SSH.

* **2026-09-25**:
  * **Decision**: Dropped `set paste` from the old vimrc.
  * **Reasoning**: With `paste` permanently on, insert-mode mappings and auto-indent are disabled. Modern Vim handles bracketed paste automatically.

* **2026-09-25**:
  * **Decision**: Added `:Ask` / `Space a`, which streams an LLM answer into a split. In visual mode it sends the selected code as context.
  * **Reasoning**: Mirrors `tmux-mgr ask`. The command is configurable (`g:vim_mgr_llm_cmd` or `$VIM_MGR_LLM_CMD`) and runs as an async job, so Vim doesn't block.

* **2026-09-25**:
  * **Decision**: Swap, undo and backup files go under `~/.vim/tmp/`, with persistent undo enabled.
  * **Reasoning**: Keeps project directories free of `.swp` files (the old vimrc already did this for swap files), and `u` keeps working after you close and reopen a file.

* **2026-09-25**:
  * **Decision**: Restored pear-tree (auto-close pairs), prettyxml, jdaddy, the `\fn` insert mapping and `tabpagemax=100` from the old vimrc.
  * **Reasoning**: They were part of the old day-to-day workflow and were dropped by mistake in the first version.
