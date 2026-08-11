# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export SHELL_SESSIONS_DISABLE=1

# Rust / Cargo
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export PATH="$CARGO_HOME/bin:$PATH"

# Node.js (npm)
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Conda
export CONDARC="$XDG_CONFIG_HOME/conda/condarc"

# Ollama
export OLLAMA_MODELS="$XDG_DATA_HOME/ollama/models"

# Go
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"

# Global Editor
export EDITOR=nvim
export VISUAL=nvim

# Custom binaries
typeset -U path PATH
export PATH="$HOME/.local/bin:$HOME/repos/utils/bin:$PATH"

# Added by Antigravity IDE
export PATH="/Users/saksham/.antigravity-ide/antigravity-ide/bin:$PATH"

# Homebrew Bundle Configuration
export HOMEBREW_BUNDLE_FILE="$HOME/repos/etc/Brewfile"
