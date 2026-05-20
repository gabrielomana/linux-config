# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN DE USUARIO - ZSH V2 CORE
# ──────────────────────────────────────────────────────────────────────────────

# Ruta del framework Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"

# Desactivar tema interno de OMZ para delegar control visual a Starship
ZSH_THEME=""

# Plugins nucleares activos (Ya clonados por el Script 3)
plugins=(
    git 
    zsh-autosuggestions 
    zsh-syntax-highlighting 
    sudo 
    command-not-found
)

# Cargar Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# Cargar la matriz de alias compartidos si existe
if [ -f "$HOME/.aliases" ]; then
    source "$HOME/.aliases"
fi

# Inicializar los prompts y motores interactivos en caliente
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# Integración nativa del buscador difuso FZF en Fedora
source /usr/share/fzf/shell/key-bindings.zsh 2>/dev/null || true
source /usr/share/fzf/shell/completion.zsh 2>/dev/null || true

# Ejecutar diagnóstico visual al abrir la terminal
if command -v fastfetch &> /dev/null; then
    fastfetch
fi
