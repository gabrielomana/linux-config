#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Script de instalación de ZSH + Starship para root
# Autor: Gabriel Omaña / Initium
# Requiere ejecución como root real
# ───────────────────────────────────────────────────────────────

# 🛡️ Autoelevación si es necesario
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[INFO] Elevando permisos para ejecutar como root..."
  exec sudo bash "$0" "$@"
fi

# 🔐 Validación obligatoria
[[ "$(id -u)" -ne 0 ]] && { echo "[FATAL] No se pudo elevar permisos. Abortando."; exit 1; }

echo "[INFO] Instalando ZSH y Starship para el usuario root..."

# ───── Instalación de paquetes requeridos ─────
dnf install -y zsh starship git curl wget &>/dev/null || {
  echo "[ERROR] Fallo al instalar dependencias."
  exit 1
}

# ───── Instalación de Oh-My-Zsh ─────
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes
export ZSH="/root/.oh-my-zsh"

if [[ ! -d "$ZSH" ]]; then
  echo "[INFO] Instalando Oh-My-Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "[INFO] Oh-My-Zsh ya está instalado en root. Se omite."
fi

# ───── Configuración de ZSH por defecto ─────
chsh -s "$(which zsh)" root

# ───── Creación de .zshrc ─────
ZSHRC_PATH="/root/.zshrc"

cat > "$ZSHRC_PATH" <<EOF
export ZSH="/root/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source \$ZSH/oh-my-zsh.sh

eval "\$(starship init zsh)"
EOF

chmod 644 "$ZSHRC_PATH"

# ───── Configuración de Starship ─────
mkdir -p /root/.config
cat > /root/.config/starship.toml <<EOF
add_newline = false

[character]
success_symbol = "[➜](bold green) "
EOF

echo "[OK] ZSH y Starship configurados correctamente para root."
