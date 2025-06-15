#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] Fallo en $0, línea $LINENO" >&2; exit 1'

PROJECT_ROOT="$(dirname "$0")"
source "$PROJECT_ROOT/KDE_PLASMA/functions/init_env.sh"

LOGDIR="$HOME/sparky_logs"
mkdir -p "$LOGDIR"
exec > >(tee -a "$LOGDIR/reset.log") \
     2> >(tee -a "$LOGDIR/reset.err" >&2)

log_section "🔄 Reiniciando entorno SparkyLinux"

require_cmd git
require_cmd sudo
require_cmd chmod

REPO_PATH="/git/linux-config"
if [[ ! -d "$REPO_PATH/.git" ]]; then
  log_error "Repositorio no encontrado en $REPO_PATH"
  exit 1
fi

cd "$REPO_PATH"

run_cmd sudo git reset --hard
run_cmd sudo git pull origin main
run_cmd sudo chmod +x /git/* -R

log_success "✅ Repositorio restaurado y actualizado"

"$PROJECT_ROOT/1-pre_install.sh"
log_success "✅ Reset completo"
