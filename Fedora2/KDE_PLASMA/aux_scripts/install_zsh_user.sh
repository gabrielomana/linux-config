#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Script de instalación de ZSH + Starship para el usuario normal
# Compatible con ejecución desde sudo -u "$SUDO_USER"
# Autor: Gabriel Omaña / Initium
# ───────────────────────────────────────────────────────────────

# 🧠 Determinar el usuario y home de forma robusta
if [[ "$(id -u)" -eq 0 ]]; then
  echo "[INFO] Este script está siendo invocado por root pero ejecutado para el usuario final."
  echo "[INFO] Continuando configuración para: $SUDO_USER"
  USER_NAME="$SUDO_USER"
  USER_HOME="/home/$SUDO_USER"
else
  USER_NAME="$(whoami)"
  USER_HOME="$HOME"
fi

USER_ZSH="$USER_HOME/.oh-my-zsh"
USER_CONFIG="$USER_HOME/.config"
USER_ZSHRC="$USER_HOME/.zshrc"

echo "[INFO] Configurando ZSH y Starship para el usuario: $USER_NAME"

# ───── Verificar binarios requeridos ─────
for bin in zsh starship git curl; do
  if ! command -v "$bin" &>/dev/null; then
    echo "[ERROR] El binario '$bin' no está disponible en PATH."
    exit 1
  fi
done

# ───── Instalar Oh-My-Zsh si no existe ─────
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes
export ZSH="$USER_ZSH"

if [[ ! -d "$ZSH" ]]; then
  echo "[INFO] Instalando Oh-My-Zsh en $ZSH..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "[INFO] Oh-My-Zsh ya está instalado. Se omite."
fi

# ───── Establecer ZSH como shell por defecto ─────
ZSH_BIN="$(command -v zsh)"
if command -v chsh &>/dev/null; then
  echo "[INFO] Estableciendo ZSH como shell por defecto para $USER_NAME"
  chsh -s "$ZSH_BIN" "$USER_NAME" || echo "[WARN] No se pudo cambiar el shell automáticamente."
fi

# ───── Crear .zshrc básico ─────
echo "[INFO] Generando archivo .zshrc personalizado en $USER_ZSHRC..."

cat > "$USER_ZSHRC" <<EOF
export ZSH="$USER_ZSH"
ZSH_THEME="agnoster"
plugins=(git)

source \$ZSH/oh-my-zsh.sh

eval "\$(starship init zsh)"
EOF

chmod 644 "$USER_ZSHRC"
chown "$USER_NAME:$USER_NAME" "$USER_ZSHRC"

# ───── Crear configuración de Starship ─────
mkdir -p "$USER_CONFIG"
cat > "$USER_CONFIG/starship.toml" <<EOF
add_newline = false

[character]
success_symbol = "[➜](bold green) "
EOF

chown -R "$USER_NAME:$USER_NAME" "$USER_CONFIG"

echo "[OK] ZSH y Starship configurados correctamente para $USER_NAME"
