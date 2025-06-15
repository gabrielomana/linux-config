# ==============================================================================
# Archivo: ~/.zshrc
# Descripción: Configuración avanzada para ZSH en Fedora (KDE)
# Requiere: oh-my-zsh, starship, eza, bat, topgrade, zsh-plugins instalados
# ==============================================================================

# ------------------------------------------------------------------------------
# Powerlevel10k instant prompt (debe ir lo más arriba posible)
# ------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------------------------------
# Rutas (PATH)
# ------------------------------------------------------------------------------
export PATH="$HOME/bin:$HOME/.cargo/bin:/usr/local/bin:/usr/local/sbin:$PATH"

# ------------------------------------------------------------------------------
# Oh-My-Zsh
# ------------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH/custom"
ZSH_DISABLE_COMPFIX=true

# Mejora en completado (zsh-completions)
fpath+=("${ZSH_CUSTOM}/plugins/zsh-completions/src")

# ------------------------------------------------------------------------------
# Completado interactivo
# ------------------------------------------------------------------------------
zstyle ':completion:*' menu select

# ------------------------------------------------------------------------------
# Tema y apariencia
# ------------------------------------------------------------------------------
ZSH_THEME="robbyrussell"

# ------------------------------------------------------------------------------
# Plugins activos
# ------------------------------------------------------------------------------
plugins=(
  colored-man-pages
  git
  git-extras
  fzf-tab
  zsh-autopair
  zsh-autosuggestions
  zsh-completions
  history-substring-search
  zsh-syntax-highlighting
  sudo
  dirhistory
  you-should-use
)

# ------------------------------------------------------------------------------
# Cargar Oh-My-Zsh
# ------------------------------------------------------------------------------
source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------------------------
# Alias personalizados
# ------------------------------------------------------------------------------
alias zshr="source ~/.zshrc"
alias ocat="/usr/bin/cat"
alias fupdate="topgrade && sudo hblock -O /etc/host"
alias lastversion="~/.local/pipx/venvs/lastversion"
alias kedit="/usr/bin/featherpad"
alias nano="nano -l"
alias ytmdesktop="/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=start-ytmdesktop.sh --file-forwarding app.ytmdesktop.ytmdesktop"

# Uso de bat como reemplazo de cat
if command -v bat &> /dev/null; then
  alias cat="bat -f"
fi

# ------------------------------------------------------------------------------
# Alias extendidos con eza
# ------------------------------------------------------------------------------
if command -v eza &> /dev/null; then
  alias l="eza"
  function ls() {
    if [[ $# -eq 0 ]]; then
      eza --group-directories-first --icons
    else
      case $1 in
        ls) shift; eza "$@" --group-directories-first --icons ;;
        ll) shift; eza "$@" -lbGFhmua --group-directories-first --no-permissions --icons ;;
        llp) shift; eza "$@" -lbGFhmua --group-directories-first --icons ;;
        la) shift; eza "$@" -a --group-directories-first --icons ;;
        lt) shift; eza "$@" --tree --level=2 --icons ;;
        lt3) shift; eza "$@" --tree --level=3 --icons ;;
        lt4) shift; eza "$@" --tree --level=4 --icons ;;
        *) 
          if [ -t 1 ]; then
            eza "$@" --group-directories-first --icons --color
          else
            eza "$@" --group-directories-first --icons
          fi
          ;;
      esac
    fi
  }
else
  alias ls="ls --color=auto"
fi

# ------------------------------------------------------------------------------
# Prompt personalizado
# ------------------------------------------------------------------------------
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ------------------------------------------------------------------------------
# Soporte para terminales tipo Tilix/VTE
# ------------------------------------------------------------------------------
if [[ $TILIX_ID ]] || [[ $VTE_VERSION ]]; then
  source /etc/profile.d/vte.sh
fi

# ------------------------------------------------------------------------------
# Starship prompt (último para evitar conflictos)
# ------------------------------------------------------------------------------
eval "$(starship init zsh)"