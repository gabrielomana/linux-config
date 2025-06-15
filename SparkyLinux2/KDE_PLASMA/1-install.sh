#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] Fallo en $0, línea $LINENO" >&2; exit 1'

PROJECT_ROOT="$(dirname "$0")/../.."
source "$PROJECT_ROOT/KDE_PLASMA/functions/init_env.sh"
source "$PROJECT_ROOT/KDE_PLASMA/functions/functions.sh"

LOGDIR="$HOME/sparky_logs"
mkdir -p "$LOGDIR"
exec > >(tee -a "$LOGDIR/1-install.log") \
     2> >(tee -a "$LOGDIR/1-install.err" >&2)

log_section "🛠 Instalación de entorno gráfico y herramientas base"

require_cmd sudo
require_cmd apt

run_cmd sudo apt-get update

# Verificar si ya hay sesión KDE instalada
if command -v plasmashell &>/dev/null; then
  log_warn "El entorno KDE Plasma ya está instalado. Continuando con verificación de apps..."
else
  log_info "KDE Plasma no detectado, procederemos con su instalación."
fi

# Procesar múltiples listas si deseas escalar (por ahora, solo install.list)
LIST_FILES=("$PROJECT_ROOT/KDE_PLASMA/sources/install.list")

for list_file in "${LIST_FILES[@]}"; do
  if [[ ! -f "$list_file" ]]; then
    log_error "No se encontró el archivo de lista de paquetes: $list_file"
    exit 1
  fi

  mapfile -t packages < "$list_file"
  install_pkgs_if_missing "${packages[@]}"
done

# Habilitar display manager
enable_service_if_available sddm

# Limpieza de sistema
log_section "🧹 Limpiando paquetes no necesarios y cache"
run_cmd sudo apt-get autoremove -y
run_cmd sudo apt-get clean

# Registrar paquetes instalados
log_info "Registrando paquetes instalados..."
dpkg -l | grep ^ii | awk '{print $2}' > "$LOGDIR/packages_installed.log"
log_success "Listado generado en $LOGDIR/packages_installed.log"

log_success "✅ Instalación de entorno gráfico completada"


log_success "✅ Sistema KDE instalado correctamente"
log_info "🧾 Puedes revisar logs y lista de paquetes en: $LOGDIR"

# Reboot opcional
echo -e "\n⚠️ Se recomienda reiniciar el sistema para aplicar cambios."
read -rp "¿Deseas reiniciar ahora? [s/S para confirmar]: " choice
if [[ "$choice" =~ ^[sS]$ ]]; then
  log_info "♻ Reiniciando el sistema..."
  run_cmd sudo reboot
else
  log_info "🚪 Reinicio omitido por el usuario."
fi
