# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN BASH CONFIG (FALLBACK DE SEGURIDAD)
# ──────────────────────────────────────────────────────────────────────────────

# Cargar configuraciones globales de Fedora
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Heredar todos los alias modernos y variables de entorno
if [ -f "$HOME/.aliases" ]; then
    source "$HOME/.aliases"
fi

# Activar motor de salto inteligente en Bash
eval "$(zoxide init bash)"
