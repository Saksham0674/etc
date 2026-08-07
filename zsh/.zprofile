# Faster Homebrew initialization
if [[ ! -s ~/.cache/zsh/brew.zsh || ~/.cache/zsh/brew.zsh -ot /opt/homebrew/bin/brew ]]; then
    /opt/homebrew/bin/brew shellenv > ~/.cache/zsh/brew.zsh
fi
source ~/.cache/zsh/brew.zsh
