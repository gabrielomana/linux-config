#!/usr/bin/env bash
# ==============================================================================
# Funciones específicas para instalación y postinstalación de SparkyLinux
# ==============================================================================

# Instala una lista de paquetes si no están presentes
install_pkgs_if_missing() {
  local pkgs=("$@")
  local to_install=()

  for pkg in "${pkgs[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      to_install+=("$pkg")
    else
      log_info "Paquete '$pkg' ya instalado. Se omite."
    fi
  done

  if [[ ${#to_install[@]} -gt 0 ]]; then
    log_section "📦 Instalando paquetes: ${to_install[*]}"
    run_cmd sudo apt-get install -y --no-install-recommends "${to_install[@]}"
  else
    log_success "Todos los paquetes ya están presentes."
  fi
}

# Habilita un servicio systemd si existe
enable_service_if_available() {
  local service="$1"
  if systemctl list-unit-files | grep -q "^${service}.service"; then
    run_cmd sudo systemctl enable "$service"
    log_success "Servicio '$service' habilitado correctamente"
  else
    log_warn "El servicio '$service' no existe. Se omite."
  fi
}
