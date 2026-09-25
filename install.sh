#!/usr/bin/env bash
set -euo pipefail

# This script bootstraps the vim-mgr setup. It clones the repo into a hidden
# safe directory and links the CLI tool into the user's PATH.

REPO_URL="${REPO_URL:-https://github.com/thomasehardt/vim-by-llm.git}"
INSTALL_DIR="${VIM_MGR_DIR:-$HOME/.local/share/vim-mgr}"
BIN_DIR="$HOME/.local/bin"

echo "=> Bootstrapping vim-mgr..."

if [ -d "$INSTALL_DIR" ]; then
    echo "=> Updating existing installation in $INSTALL_DIR..."
    git -C "$INSTALL_DIR" pull --quiet
else
    echo "=> Cloning repository to $INSTALL_DIR..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/bin/vim-mgr" "$BIN_DIR/vim-mgr"

echo "=> Running vim-mgr install..."
VIM_MGR_DIR="$INSTALL_DIR" "$BIN_DIR/vim-mgr" install

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    rc_file=""
    case "${SHELL:-}" in
        */zsh) rc_file="$HOME/.zshrc" ;;
        */bash) rc_file="$HOME/.bashrc" ;;
        */fish) rc_file="$HOME/.config/fish/config.fish" ;;
    esac

    echo ""
    echo "============================================================"
    echo " WARNING: $BIN_DIR is not in your PATH."
    
    if [ -n "$rc_file" ]; then
        echo " It looks like you are using $(basename "${SHELL:-}")."
        echo " You can add it by running:"
        if [[ "$rc_file" == *fish* ]]; then
            echo "   fish_add_path $BIN_DIR"
        else
            echo "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> $rc_file"
        fi
        
        # Interactive prompt if we have a real terminal (works even when piped from curl)
        if command -v tty >/dev/null 2>&1 && { tty -s </dev/tty; } 2>/dev/null; then
            echo
            read -p " Would you like me to append this for you now? [y/N] " -n 1 -r </dev/tty
            echo
            if [[ ${REPLY:-} =~ ^[Yy]$ ]]; then
                if [[ "$rc_file" == *fish* ]]; then
                    fish -c "fish_add_path $BIN_DIR" 2>/dev/null || echo " Failed to update fish path."
                else
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc_file"
                fi
                echo " Added! Please restart your terminal or run: source $rc_file"
            fi
        fi
    else
        echo " To use the 'vim-mgr' command globally, please add:"
        echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo " to your shell's configuration file."
    fi
    echo "============================================================"
fi
