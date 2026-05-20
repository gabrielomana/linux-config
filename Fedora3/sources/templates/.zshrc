export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting sudo command-not-found)
source $ZSH/oh-my-zsh.sh

if [ -f "$HOME/.aliases" ]; then
    source "$HOME/.aliases"
fi

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source /usr/share/fzf/shell/key-bindings.zsh 2>/dev/null || true
source /usr/share/fzf/shell/completion.zsh 2>/dev/null || true

if command -v fastfetch &> /dev/null; then
    fastfetch
fi
