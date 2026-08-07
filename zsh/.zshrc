# =============================================================================
# 1. ZSH OPTIONS & HISTORY
# =============================================================================
export HISTFILE="$HOME/.local/state/zsh/history"
export SHELL_SESSION_DIR="$HOME/.local/state/zsh/sessions"
HISTSIZE=5000
SAVEHIST=5000

setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# Auto cd into directories without typing 'cd'
setopt AUTO_CD
cdpath=(~ $cdpath)

# =============================================================================
# 2. KEYBINDINGS
# =============================================================================
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# =============================================================================
# 3. ALIASES
# =============================================================================
alias ff='fastfetch'
alias restart='exec $SHELL'

# git
alias glog='git --no-pager log --graph --oneline -10'

# tmux
alias tt='tmux'
alias ttn='tmux new'
alias tta='tmux a'
alias ttls='tmux ls'

# eza (ls/tree replacement)
_EZA='eza --icons=always --color=always --group-directories-first --hyperlink'
alias ls="$_EZA"
alias lla="$_EZA -la --git --header"
alias llas="$_EZA -la --git --header --total-size"
alias trees="$_EZA --tree -a"

# neovim
alias nv="nvim"
alias mn="NVIM_APPNAME=nvim-dtfs nvim"

alias lazy="NVIM_APPNAME=nvim-distros/lazyvim nvim"
alias astro="NVIM_APPNAME=nvim-distros/astronvim nvim"
alias nvchad="NVIM_APPNAME=nvim-distros/nvchad nvim"

# Clean up temp alias variables
unset _EZA

# =============================================================================
# 4. CUSTOM FUNCTIONS
# =============================================================================
# mkdir + cd in one step
mkcd() { mkdir -p "$1" && cd "$1" }

# touch with auto-created parent dirs
touchp() {
  for f in "$@"; do
    mkdir -p "$(dirname "$f")" && touch "$f"
  done
}

# =============================================================================
# 5. TOOL INTEGRATIONS (Lazy Loads & Caches)
# =============================================================================
# Conda (lazy loaded)
conda() {
    unfunction conda
    __conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    fi
    unset __conda_setup
    conda "$@"
}

mkdir -p ~/.cache/zsh

# Starship (Cached)
if [[ ! -s ~/.cache/zsh/starship.zsh || ~/.cache/zsh/starship.zsh -ot "$commands[starship]" ]]; then
    starship init zsh > ~/.cache/zsh/starship.zsh
fi
source ~/.cache/zsh/starship.zsh

# FZF (Cached)
if [[ ! -s ~/.cache/zsh/fzf.zsh || ~/.cache/zsh/fzf.zsh -ot "$commands[fzf]" ]]; then
    fzf --zsh > ~/.cache/zsh/fzf.zsh
fi
source ~/.cache/zsh/fzf.zsh

# Zoxide (Cached)
if [[ ! -s ~/.cache/zsh/zoxide.zsh || ~/.cache/zsh/zoxide.zsh -ot "$commands[zoxide]" ]]; then
    zoxide init zsh > ~/.cache/zsh/zoxide.zsh
fi
source ~/.cache/zsh/zoxide.zsh

# =============================================================================
# 6. AUTOCOMPLETION & PLUGINS
# =============================================================================
# Autocompletion
zcompdump="$XDG_CACHE_HOME/zsh/zcompdump"
autoload -Uz compinit
compinit -C -d "$zcompdump"
if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
    zcompile "$zcompdump" &!
fi

# Move zcompcache out of ZDOTDIR and into XDG_CACHE_HOME
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# Zsh Autosuggestions
source $HOME/repos/opt/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^f' autosuggest-accept # ctrl+f to accept suggestion

# Zsh Syntax Highlighting (MUST BE ABSOLUTELY LAST)
source $HOME/repos/opt/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
