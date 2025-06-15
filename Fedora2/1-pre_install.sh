#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ──────────────────────────────
# 🧱 Variables de entorno básicas
# ──────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGDIR="$HOME/fedora_logs"
mkdir -p "$LOGDIR"

exec > >(tee -a "$LOGDIR/install.log") 2> >(tee -a "$LOGDIR/error.log" >&2)

# ──────────────────────────────
# 🎨 Colores y funciones UI
# ──────────────────────────────
GREEN='\e[1;32m'
RED='\e[1;31m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
NC='\e[0m'

print_action()    { echo -e "${BLUE}▶ $1...${NC}"; }
print_status_ok() { echo -e "    ${GREEN}(OK)${NC}"; }
print_status_fail(){ echo -e "    ${RED}(FAIL)${NC}"; }
print_question()  { echo -e "${YELLOW}$1${NC}"; }
log_section()     { echo -e "\n${BLUE}🔷 ===== $1 =====${NC}"; }

run_step() {
  local desc="$1"
  shift
  print_action "$desc"
  if "$@" >>"$LOGDIR/install.log" 2>>"$LOGDIR/error.log"; then
    print_status_ok
  else
    print_status_fail
    echo "[WARN] Fallo en: $desc" >>"$LOGDIR/error.log"
    return 1
  fi
}

install_packages() {
  local desc="$1"
  shift
  run_step "$desc"     dnf install -y --allowerasing --skip-broken --setopt=skip_if_unavailable=true "$@"
}

# ──────────────────────────────
# 🚀 Inicio del pre-install
# ──────────────────────────────
log_section "🚀 Pre-Instalación Fedora Refactor"

run_step "Actualizando caché de DNF" dnf makecache

install_packages "Instalando paquetes base" nano curl wget git

install_packages "Instalando herramientas del sistema" htop neofetch

log_section "✅ Pre-instalación completada"
echo -e "\n${GREEN}✔ El sistema ha sido preparado exitosamente para la instalación posterior.${NC}"
echo -e "📁 Logs: ${BLUE}$LOGDIR/install.log${NC}, ${BLUE}$LOGDIR/error.log${NC}\n"
