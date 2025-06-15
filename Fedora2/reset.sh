#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Ruta al repositorio local
REPO_DIR="/git/linux-config"
REPO_URL="https://github.com/gabrielomana/linux-config"
BRANCH="main"

echo "🔄 Reiniciando repositorio en: $REPO_DIR"

# Validar existencia del repositorio
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "❌ La ruta '$REPO_DIR' no contiene un repositorio Git válido." >&2
  exit 1
fi

cd "$REPO_DIR"

# Reset duro y limpieza
echo "🔁 git reset --hard origin/$BRANCH"
git fetch origin
git reset --hard "origin/$BRANCH"
git clean -fd

# Pull remoto explícito (reafirma URL y branch)
echo "⬇️  git pull desde $REPO_URL [$BRANCH]"
git pull "$REPO_URL" "$BRANCH"

# Permisos de ejecución
echo "🔐 Aplicando permisos +x a todos los archivos"
chmod -R +x "$REPO_DIR"

# Conversión a formato UNIX
if ! command -v dos2unix &>/dev/null; then
  echo "⚠️  dos2unix no está instalado. Instalando..."
  dnf install -y dos2unix
fi

echo "🧽 Convirtiendo todos los archivos a formato UNIX"
find "$REPO_DIR" -type f -exec dos2unix {} \;

echo "✅ Repositorio sincronizado, permisos aplicados y formato UNIX asegurado."
