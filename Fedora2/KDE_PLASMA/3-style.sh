#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Fedora KDE Styler - Runner principal
# Autor: Gabriel Omaña / Initium
# Última actualización: 2025-06-14
# Ejecutar como: sudo ./style.sh
# ───────────────────────────────────────────────────────────────

set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/fedora_logs"
LOG_FILE="$LOG_DIR/style.log"
ERR_FILE="$LOG_DIR/style.err"

mkdir -p "$LOG_DIR"

log_info()    { echo -e "[INFO]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE"; }
log_warn()    { echo -e "[WARN]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE" >&2; }
log_error()   { echo -e "[ERROR] $(date '+%F %T')  $*" | tee -a "$LOG_FILE" "$ERR_FILE" >&2; exit 1; }
log_success() { echo -e "[ OK ]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE"; }

trap 'log_error "Fallo inesperado en la línea $LINENO del script $SCRIPT_NAME."' ERR

# ───── Validación de root ─────
if [[ "$(id -u)" -ne 0 ]]; then
  log_error "Este script debe ejecutarse como root. Abortando."
fi

# ───── Funciones internas ─────

install_popos_icons() {
  ICON_NAME="Pop_Os-Icons"
  ICON_URL="https://github.com/gabrielomana/Pop_Os-Icons/raw/main/${ICON_NAME}.tar.gz"
  ICON_DEST="/usr/share/icons"
  ICON_TMP="/tmp/${ICON_NAME}.tar.gz"

  log_info "🎨 Instalando íconos $ICON_NAME..."
  if [[ -d "$ICON_DEST/$ICON_NAME" ]]; then
    log_warn "Los íconos $ICON_NAME ya están instalados. Se omite."
  else
    wget -O "$ICON_TMP" "$ICON_URL" &>> "$LOG_FILE" || log_error "Fallo al descargar $ICON_NAME"
    tar -xf "$ICON_TMP" -C "$ICON_DEST" &>> "$LOG_FILE" || log_error "Fallo al extraer íconos"
    rm -f "$ICON_TMP"
    log_success "Íconos $ICON_NAME instalados correctamente."
  fi
}

install_phinger_cursors() {
  CURSOR_NAME="phinger-cursors"
  CURSOR_URL="https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2"
  CURSOR_TMP="/tmp/${CURSOR_NAME}.tar.bz2"
  CURSOR_DEST="/usr/share/icons/${CURSOR_NAME}"

  log_info "🖱️ Instalando cursores $CURSOR_NAME..."
  if [[ -d "$CURSOR_DEST" ]]; then
    log_warn "Cursores $CURSOR_NAME ya instalados. Se omite."
  else
    wget -O "$CURSOR_TMP" "$CURSOR_URL" &>> "$LOG_FILE" || log_error "Fallo al descargar cursores"
    tar -xjf "$CURSOR_TMP" -C /usr/share/icons/ &>> "$LOG_FILE" || log_error "Fallo al extraer cursores"
    rm -f "$CURSOR_TMP"
    log_success "Cursores $CURSOR_NAME instalados correctamente."
  fi
}

install_papirus_kvantum() {
  log_info "🎨 Instalando íconos Papirus y motor Kvantum..."
  dnf install -y papirus-icon-theme "kvantum*" &>> "$LOG_FILE" || \
    log_error "Fallo al instalar Papirus/Kvantum"
  log_success "Papirus y Kvantum instalados correctamente."
}

open_customization_guide() {
  PDF_PATH="$BASE_DIR/customization_guide.pdf"
  log_info "📘 Intentando abrir guía de personalización..."
  if ! command -v okular &>/dev/null; then
    log_warn "Okular no está instalado. Se omite apertura del PDF."
    return
  fi
  if [[ ! -f "$PDF_PATH" ]]; then
    log_warn "No se encontró el archivo $PDF_PATH."
    return
  fi
  if [[ -n "${DISPLAY:-}" ]]; then
    nohup okular "$PDF_PATH" &> /dev/null &
    log_success "Guía de personalización abierta."
  else
    log_warn "No hay entorno gráfico disponible (DISPLAY no definido)."
  fi
}

apply_cleanup() {
  log_info "🧹 Ejecutando limpieza del sistema..."
  if command -v bleachbit &>/dev/null; then
    bleachbit --clean system.tmp system.trash system.cache system.localizations system.desktop_entry &>> "$LOG_FILE" || \
      log_warn "Limpieza con bleachbit fallida"
    log_success "Limpieza con bleachbit completada."
  else
    log_warn "Bleachbit no instalado. Se omite limpieza adicional."
  fi
  dnf clean all &>> "$LOG_FILE" || log_warn "Fallo al limpiar DNF"
  dnf update -y &>> "$LOG_FILE" || log_warn "Fallo durante dnf update"
  dnf upgrade -y &>> "$LOG_FILE" || log_warn "Fallo durante dnf upgrade"
  log_success "Sistema actualizado y limpiado correctamente."
}

run_root_phase() {
  local phase_script="$1"
  if [[ -x "$phase_script" ]]; then
    log_info "▶ Ejecutando fase root: $(basename "$phase_script")"
    "$phase_script"
    log_success "✔ Finalizó fase root: $(basename "$phase_script")"
  else
    log_warn "⛔ Fase root omitida: $phase_script no ejecutable"
  fi
}

run_user_phase() {
  local user_script="$1"
  if [[ -n "${SUDO_USER:-}" && -x "$user_script" ]]; then
    log_info "👤 Ejecutando fase usuario: $(basename "$user_script")"
    sudo -u "$SUDO_USER" bash "$user_script"
    log_success "✔ Fase usuario completada: $(basename "$user_script")"
  else
    log_warn "⛔ Fase usuario omitida: $user_script no ejecutable o sin SUDO_USER definido"
  fi
}

# ───── Secuencia de fases con barra de progreso ─────
PHASES_TOTAL=9
PHASE_CURRENT=1

progress() {
  echo -ne "[$PHASE_CURRENT/$PHASES_TOTAL] ▶ $1\n"
  ((PHASE_CURRENT++))
}

log_info "🧩 Iniciando personalización de Fedora KDE..."

progress "Instalando íconos Pop!_OS"
install_popos_icons

progress "Instalando cursores Phinger"
install_phinger_cursors

progress "Instalando Papirus y Kvantum"
install_papirus_kvantum

progress "Tema Win11OS (root)"
run_root_phase "$BASE_DIR/aux/install_win11os_theme.sh"

progress "Cursores Win10OS (root)"
run_root_phase "$BASE_DIR/aux/install_win10os_cursors.sh"

progress "Tema Orchis (root)"
run_root_phase "$BASE_DIR/aux/install_orchis_theme.sh"

progress "Repositorio Klassy (root)"
run_root_phase "$BASE_DIR/aux/install_klassy_style.sh"

progress "Configurando ZSH para root"
run_root_phase "$BASE_DIR/aux/install_zsh_root.sh"

progress "Configurando ZSH para usuario"
run_user_phase "$BASE_DIR/aux/install_zsh_user.sh"

open_customization_guide
apply_cleanup

log_info "🎉 Personalización completa. Revisa el log en $LOG_FILE"


# ───── Compatibilidad extra (HiDPI) ─────
if [[ "${XCURSOR_SIZE:-}" == "" && "$(env | grep -i scale)" =~ "2" ]]; then
  export XCURSOR_SIZE=48
  echo "[INFO] XCURSOR_SIZE ajustado a 48 para compatibilidad HiDPI."
fi
