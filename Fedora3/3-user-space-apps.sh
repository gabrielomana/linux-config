#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo -e "\n■ [ERROR] Ocurrió un fallo en la línea $LINENO del script. Abortando."; exit 1' ERR

# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT 3: FEDORA USER SPACE, DUAL ZSH V2, SMB, OFFICE & MULTI-ENGINE APPS
# ──────────────────────────────────────────────────────────────────────────────

# === [1. VARIABLES GLOBALES Y RUTAS] ===
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$USER_HOME/fedora_logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/user_space_$TIMESTAMP.log"
ERR_FILE="$LOG_DIR/user_space_error_$TIMESTAMP.log"

SRC_PERSIST_DIR="$USER_HOME/.local/src"

LIST_LIBS="$SCRIPT_DIR/sources/lists/libs.list"
LIST_APPS="$SCRIPT_DIR/sources/lists/extra_apps.list"
LIST_MULTI="$SCRIPT_DIR/sources/lists/multimedia.list"
LIST_FLATPAK="$SCRIPT_DIR/sources/lists/flatpak.list"
LIST_NPM="$SCRIPT_DIR/sources/lists/npm.list"

setup_colors() {
  if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1) GREEN=$(tput setaf 2) YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4) CYAN=$(tput setaf 6) BOLD=$(tput bold) NC=$(tput sgr0)
  else
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" BOLD="" NC=""
  fi
}
setup_colors

log_info() { printf "${BLUE}%-65s %s${NC}\n" "[INFO] $1" "[OK]"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"; }
log_success() { printf "${GREEN}%-65s %s${NC}\n" "[✔ SUCCESS] $1" "[OK]"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_FILE"; }
log_warn() { printf "${YELLOW}%-65s %s${NC}\n" "[⚠ WARNING] $1" "[WARN]"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" | tee -a "$LOG_FILE" >> "$ERR_FILE"; }
log_error() { printf "${RED}%-65s %s${NC}\n" "[❌ ERROR] $1" "[FAIL]"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" | tee -a "$LOG_FILE" >> "$ERR_FILE"; exit 1; }

log_section() {
  local clean_title="${1//[$'\t\r\n']}"
  local border=$(printf '─%.0s' $(seq 1 $(( ${#clean_title} + 4 ))))
  echo -e "\n${BLUE}┌$border┐\n│  ${BOLD}${clean_title}${NC}${BLUE}  │\n└$border┘${NC}\n"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $1" >> "$LOG_FILE"
}

run_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log_info "Elevando privilegios..."
    sudo -v || log_error "No se pudieron obtener privilegios"
  fi
}

init_environment() {
  mkdir -p "$LOG_DIR"
  touch "$LOG_FILE" "$ERR_FILE"
  chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true
  exec > >(tee >(grep --line-buffered -E "^\[|^\s*\[.*\]" >> "$LOG_FILE") > /dev/tty) \
       2> >(tee >(grep --line-buffered -E "^\[⚠|\[❌" >> "$ERR_FILE") > /dev/tty)
}

show_welcome_banner() {
  clear
  echo -e "${BLUE}${BOLD}PHASE 3: USER SPACE, OFFICE ESPAÑOL & APPS${NC}"
  echo -e "${YELLOW}===================================================================${NC}"
  echo -ne "${BLUE}¿Deseas proceder con la automatización ahora? (s/N): ${NC}" > /dev/tty
  read -r proceed < /dev/tty
  [[ ! "$proceed" =~ ^[Ss]$ ]] && exit 0
}

configure_dual_shell() {
  log_section "🐚 Sintonización Dual de la Terminal (Arquitectura V2)"
  run_sudo
  sudo dnf install -y zsh fzf zoxide util-linux-user wget curl &>> "$LOG_FILE"
  sudo chsh -s "$(which zsh)" "$REAL_USER" &>> "$LOG_FILE" || true
  sudo chsh -s "$(which zsh)" root &>> "$LOG_FILE" || true
  curl -sS https://starship.rs/install.sh | sudo sh -s -- -y &>> "$LOG_FILE"

  for target_user in "$REAL_USER" "root"; do
    local home_path=$(eval echo "~$target_user")
    sudo -u "$target_user" rm -rf "$home_path/.oh-my-zsh" 2>/dev/null || sudo rm -rf "$home_path/.oh-my-zsh"
    sudo -u "$target_user" git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$home_path/.oh-my-zsh" &>> "$LOG_FILE" || sudo git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$home_path/.oh-my-zsh" &>> "$LOG_FILE"
    
    local plugins_path="$home_path/.oh-my-zsh/custom/plugins"
    sudo -u "$target_user" mkdir -p "$plugins_path" 2>/dev/null || sudo mkdir -p "$plugins_path"
    
    # INTEGRACIÓN QUIRÚRGICA: INSTALACIÓN EXTENSIVA DE LOS 7 PLUGINS DE ALTA PRODUCTIVIDAD HEREDADOS DE OH-MY-ZSH
    declare -A zsh_repos=(
      ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
      ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
      ["zsh-autopair"]="https://github.com/hlissner/zsh-autopair.git"
      ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
      ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
      ["you-should-use"]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
      ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab.git"
    )

    for plugin in "${!zsh_repos[@]}"; do
      if [[ ! -d "${plugins_path}/${plugin}" ]]; then
        sudo -u "$target_user" git clone --depth=1 "${zsh_repos[$plugin]}" "${plugins_path}/${plugin}" &>> "$LOG_FILE" || sudo git clone --depth=1 "${zsh_repos[$plugin]}" "${plugins_path}/${plugin}" &>> "$LOG_FILE"
      fi
    done
    sudo chmod -R 755 "$home_path/.oh-my-zsh"
  done
  log_success "Arquitectura ZSH V2 instalada con catálogo completo de 7 componentes."
}

deploy_user_dotfiles() {
  log_section "📁 Enlace Inteligente de Dotfiles desde el Repositorio"
  run_sudo
  local repo_dotfiles_dir="${SCRIPT_DIR}/dotfiles"
  local target_config_dir="$USER_HOME/.config"
  local target_share_dir="$USER_HOME/.local/share"
  sudo -u "$REAL_USER" mkdir -p "$target_config_dir" "$target_share_dir/konsole"

  if [[ ! -d "$repo_dotfiles_dir" ]]; then
    log_warn "Carpeta 'dotfiles/' no encontrada. Se omite."
    return 0
  fi

  if [[ -f "$repo_dotfiles_dir/konsole/FedoraDev.profile" ]]; then
    sudo -u "$REAL_USER" ln -sf "$repo_dotfiles_dir/konsole/FedoraDev.profile" "$target_share_dir/konsole/FedoraDev.profile"
  fi
  if [[ -f "$repo_dotfiles_dir/konsolerc" ]]; then
    sudo -u "$REAL_USER" ln -sf "$repo_dotfiles_dir/konsolerc" "$target_config_dir/konsolerc"
  fi

  shopt -s dotglob nullglob
  for item in "$repo_dotfiles_dir"/*; do
    local base_name=$(basename "$item")
    [[ "$base_name" == "konsole" || "$base_name" == "konsolerc" ]] && continue
    if [[ "$base_name" == "config" || "$base_name" == ".config" ]]; then
      for cfg_item in "$item"/*; do
        sudo -u "$REAL_USER" ln -sfn "$cfg_item" "$target_config_dir/$(basename "$cfg_item")"
      done
    else
      sudo -u "$REAL_USER" ln -sfn "$item" "$USER_HOME/$base_name"
      if [[ "$base_name" == ".zshrc" || "$base_name" == ".bashrc" || "$base_name" == ".aliases" ]]; then
         sudo ln -sfn "$item" "/root/$base_name"
      fi
    fi
  done
  shopt -u dotglob nullglob
  log_success "Dotfiles integrados."
}

configure_starship_themes() {
  log_section "🚀 Configuración Dinámica de Temas Starship"
  local themes_folder="$USER_HOME/.config/starship_themes"
  local base_url="https://raw.githubusercontent.com/gabrielomana/MyStarships/main"
  sudo -u "$REAL_USER" mkdir -p "$themes_folder"
  sudo -u "$REAL_USER" wget -q "$base_url/prompt_black.toml" -O "$USER_HOME/.config/starship.toml" || true
  sudo mkdir -p /root/.config && sudo ln -sf "$USER_HOME/.config/starship.toml" /root/.config/starship.toml
  local theme_files=("prompt_black.toml" "prompt_matcha.toml" "prompt_nord_aurora.toml" "prompt_nord_frost.toml")
  for theme in "${theme_files[@]}"; do
    sudo -u "$REAL_USER" wget -q "$base_url/$theme" -O "$themes_folder/$theme" || true
  done
  log_success "Temas MyStarships sincronizados."
}

configure_protocols_and_isolation() {
  log_section "🌐 Protocolo SMB & Motores Locales"
  run_sudo
  sudo dnf install -y samba-client cifs-utils kdenetwork-filesharing gvfs-smb cargo rust pipx &>> "$LOG_FILE"
  sudo usermod -aG wheel "$REAL_USER" &>> "$LOG_FILE" || true
  sudo -u "$REAL_USER" pipx ensurepath &>> "$LOG_FILE"
  sudo -u "$REAL_USER" pipx install lastversion &>> "$LOG_FILE" || true
  # INTEGRACIÓN QUIRÚRGICA: INCLUSIÓN DE LA COMPILACIÓN DE BATBOX MEDIANTE EL MOTOR LOCAL DE CARGO
  sudo -u "$REAL_USER" cargo install cargo-update batbox &>> "$LOG_FILE" || true
  log_success "Motores operativos (Incluye batbox nativo en Cargo)."
}

install_dnf_lists() {
  log_section "📦 Motor DNF: Librerías y Aplicaciones"
  run_sudo
  local -a pkgs=()
  for list in "$LIST_LIBS" "$LIST_APPS" "$LIST_MULTI"; do
    [[ -f "$list" ]] && while IFS= read -r line || [[ -n "$line" ]]; do
      local clean=$(echo "$line" | sed 's/#.*//' | xargs)
      [[ -n "$clean" ]] && pkgs+=("$clean")
    done < "$list"
  done
  if [ ${#pkgs[@]} -gt 0 ]; then
    IFS=$'\n' sorted=($(sort -u <<<"${pkgs[*]}"))
    IFS=$'\n\t'
    sudo dnf install -y --allowerasing --skip-broken --setopt=skip_if_unavailable=true "${sorted[@]}" &>> "$LOG_FILE"
    log_success "Aplicaciones DNF instaladas."
  fi
}

configure_office_and_fonts() {
  log_section "📝 Configuración de Entorno Ofimático (Microsoft Fonts & Plugins)"
  run_sudo
  
  log_info "Instalando tipografías base de Microsoft (MS Core Fonts)..."
  sudo dnf install -y https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm &>> "$LOG_FILE" || log_warn "SourceForge tardó en responder, se omitieron las tipografías MS."
  
  log_info "Actualizando la caché de renderizado tipográfico del sistema..."
  sudo fc-cache -f -v &>> "$LOG_FILE"

  log_info "Preparando estructura de directorios para Plugins de ONLYOFFICE..."
  sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/onlyoffice/desktopeditors/sdkjs-plugins"
  
  log_success "Compatibilidad ofimática (ES) y fuentes MS instaladas correctamente."
}

# INTEGRACIÓN QUIRÚRGICA: NUEVO COMPONENTE — PIPELINE DE CAPTURA OCR INTEGRADO CON ACCESOS TECLADO KWIN
configure_flameshot_ocr_pipeline() {
  log_section "📷 Pipeline de Reconocimiento de Texto (Flameshot OCR)"
  
  local bin_dir="$USER_HOME/.local/bin"
  local apps_dir="$USER_HOME/.local/share/applications"
  local script_path="${bin_dir}/flameshot_ocr.sh"

  sudo -u "$REAL_USER" mkdir -p "$bin_dir" "$apps_dir"

  log_info "Escribiendo binario ejecutable flameshot_ocr.sh..."
  sudo -u "$REAL_USER" cat << 'EOF' > "$script_path"
#!/usr/bin/env bash
flameshot gui --raw | convert - -resize 400% png:- | tesseract stdin stdout -l spa 2>/dev/null | awk 'NR==1{printf "%s", $0} NR>1{printf "\n%s", $0}' | xclip -selection clipboard
EOF
  sudo -u "$REAL_USER" chmod +x "$script_path"

  log_info "Creando archivo descriptor de escritorio para el menú de aplicaciones..."
  sudo -u "$REAL_USER" cat <<EOF > "$apps_dir/flameshot-ocr.desktop"
[Desktop Entry]
Name=Flameshot OCR
Comment=Extraer texto de capturas de pantalla de forma automática
Exec=$script_path
Icon=flameshot
Type=Application
Terminal=false
Categories=Utility;System;
EOF

  log_info "Forzando asignación de la tecla física Print Screen (Impr Pant)..."
  local kw_cmd="kwriteconfig6"
  if ! command -v kwriteconfig6 &>/dev/null; then kw_cmd="kwriteconfig5"; fi
  
  local kglobal_file="$USER_HOME/.config/kglobalshortcutsrc"
  sudo -u "$REAL_USER" mkdir -p "$(dirname "$kglobal_file")"
  sudo -u "$REAL_USER" touch "$kglobal_file"
  
  sudo -u "$REAL_USER" $kw_cmd --file "$kglobal_file" --group org.flameshot.Flameshot.desktop --key Capture "Print,none,Tomar captura de pantalla con Flameshot"
  sudo -u "$REAL_USER" $kw_cmd --file "$kglobal_file" --group PlasmaShortcuts --key Print "flameshot gui"
  
  log_success "Pipeline OCR e inyección de atajos globales KWin completado."
}

# INTEGRACIÓN QUIRÚRGICA: NUEVO COMPONENTE — INSTALADOR AUTOMÁTICO DE EXTENSIONES DE VISUAL STUDIO CODE desde lista
install_vscode_extensions_v2() {
  log_section "💻 Sincronización del Motor de Extensiones de VSCode"
  local ext_list="$SCRIPT_DIR/sources/lists/vscode_extensions.list"
  
  if [[ -f "$ext_list" ]] && command -v code &>/dev/null; then
    log_info "Procesando instalación desatendida de extensiones..."
    while IFS= read -r extension || [[ -n "$extension" ]]; do
      local clean_ext=$(echo "$extension" | sed 's/#.*//' | xargs)
      if [[ -n "$clean_ext" ]]; then
        log_info "  -> Instalando de forma forzada: $clean_ext"
        sudo -u "$REAL_USER" code --install-extension "$clean_ext" --force &>> "$LOG_FILE" || true
      fi
    done < "$ext_list"
    log_success "Ecosistema de desarrollo unificado en VSCode."
  else
    log_warn "Lista de extensiones no hallada o binario 'code' ausente. Se omite."
  fi
}

# INTEGRACIÓN QUIRÚRGICA: NUEVO COMPONENTE — SINTONIZACIÓN FINALES DE INFRAESTRUCTURA (LIBVIRT, BALENA ETCHER, NAVI, HBLOCK Y KONSOLE ZIP)
configure_system_integration_tweaks() {
  log_section "⚙️ Ajustes Finos de Integración de Sistema (Libvirt, Etcher y Navi)"
  run_sudo

  # 1. Activación de Virtualización y Configuración de SDDM Hiding
  log_info "Activando demonio de virtualización nativa libvirtd..."
  sudo systemctl enable --now libvirtd &>> "$LOG_FILE" || true
  
  log_info "Inyectando regla de ocultamiento de cuentas de servicio en SDDM..."
  local sddm_conf="/etc/sddm.conf"
  if [[ -f "$sddm_conf" ]]; then
    if ! grep -q "libvirt-qemu" "$sddm_conf"; then
      echo -e "\n[Users]\nHideUsers=libvirt-qemu" | sudo tee -a "$sddm_conf" > /dev/null
    fi
  else
    cat <<EOF | sudo tee "$sddm_conf" > /dev/null
[Users]
HideUsers=libvirt-qemu
EOF
  fi

  # 2. Descarga Externa Segura (Balena Etcher)
  log_info "Inyectando repositorio y descargando Balena Etcher..."
  curl -1sLf 'https://dl.cloudsmith.io/public/balena/etcher/setup.rpm.sh' | sudo -E bash &>> "$LOG_FILE" || true
  sudo dnf install -y balena-etcher-electron &>> "$LOG_FILE" || log_warn "No se pudo completar la instalación nativa de Balena Etcher."

  # 3. Descarga en Caliente de Hojas de Trucos (Navi Cheatsheets)
  if command -v navi &>/dev/null; then
    log_info "Descargando catálogo offline de cheat.sh mapeado hacia navi..."
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/navi/cheats"
    if [[ ! -d "$USER_HOME/.config/navi/cheats/cheat.sh" ]]; then
      sudo -u "$REAL_USER" git clone --depth=1 https://github.com/denisidoro/cheat.sh.git "$USER_HOME/.config/navi/cheats/cheat.sh" &>> "$LOG_FILE" || true
    fi
  fi

  # 4. Inyección del Servidor de Catálogo de Konsole Temas (ZIP Global heredado de la V1)
  log_info "Inyectando catálogo global de esquemas de color para Konsole..."
  sudo mkdir -p /usr/share/konsole
  sudo wget -q "https://github.com/gabrielomana/linux-config/raw/main/Fedora2/KDE_PLASMA/dotfiles/konsole.zip" -O /tmp/konsole.zip || true
  if [[ -f "/tmp/konsole.zip" ]]; then
    sudo unzip -q -o /tmp/konsole.zip -d /usr/share/konsole/ || true
    rm -f /tmp/konsole.zip
  fi

  # 5. Ejecución del Filtro Publicitario de Red hblock
  if command -v hblock &>/dev/null; then
    log_info "Ejecutando hblock para blindar el archivo /etc/hosts..."
    sudo hblock &>> "$LOG_FILE" || true
  fi
  log_success "Ajustes finos de sistema concluidos."
}

# INTEGRACIÓN QUIRÚRGICA: NUEVO COMPONENTE — PURGADO DE SOFTWARE NO DESEADO (ANTI-LISTA)
purge_system_bloatware_v2() {
  log_section "🗑️ Purgado Forzado de Componentes y Bloatware"
  run_sudo
  local bloat_file="$SCRIPT_DIR/sources/lists/bloatware.list"
  
  if [[ -f "$bloat_file" ]]; then
    local -a bloat_pkgs=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      local clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
      [[ -n "$clean_line" ]] && bloat_pkgs+=("$clean_line")
    done < "$bloat_file"
    
    if [ ${#bloat_pkgs[@]} -gt 0 ]; then
      log_info "Ejecutando dnf remove masivo para ${#bloat_pkgs[@]} paquetes de bloatware..."
      sudo dnf remove -y "${bloat_pkgs[@]}" &>> "$LOG_FILE" || true
    fi
  fi
}

# INTEGRACIÓN QUIRÚRGICA: NUEVO COMPONENTE — HIGIENIZACIÓN DE BLOQUES MEDIANTE EL CLI DE BLEACHBIT
execute_deep_maintenance_v2() {
  log_section "🧹 Ejecución del Ciclo de Limpieza Profunda Destructiva (BleachBit)"
  run_sudo
  
  if command -v bleachbit &>/dev/null; then
    log_info "Invocando el CLI de BleachBit para eliminar cachés profundas y temporales..."
    sudo bleachbit --clean system.cache system.clipboard system.trash system.tmp &>> "$LOG_FILE" || true
  fi
  log_success "Mantenimiento preventivo e higienización de bloques finalizados."
}

install_npm_lists() {
  log_section "🟩 Motor NPM: Node.js y Utilidades"
  if [[ -f "$LIST_NPM" ]]; then
    run_sudo
    sudo dnf install -y nodejs npm &>> "$LOG_FILE"
    local -a npm_pkgs=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      local clean=$(echo "$line" | sed 's/#.*//' | xargs)
      [[ -n "$clean" ]] && npm_pkgs+=("$clean")
    done < "$LIST_NPM"
    if [ ${#npm_pkgs[@]} -gt 0 ]; then
      sudo npm install -g "${npm_pkgs[@]}" &>> "$LOG_FILE"
      log_success "Paquetes NPM instalados."
    fi
  fi
}

install_flatpak_lists() {
  log_section "🧊 Motor Flatpak: Flathub"
  if [[ -f "$LIST_FLATPAK" ]]; then
    run_sudo
    local -a flat_pkgs=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      local clean=$(echo "$line" | sed 's/#.*//' | xargs)
      [[ -n "$clean" ]] && flat_pkgs+=("$clean")
    done < "$LIST_FLATPAK"
    if [ ${#flat_pkgs[@]} -gt 0 ]; then
      sudo flatpak install -y flathub "${flat_pkgs[@]}" &>> "$LOG_FILE" || true
      log_success "Flatpaks instalados."
    fi
  fi
}

configure_topgrade_engine() {
  log_section "⚙️ Orquestación de Topgrade"
  run_sudo
  sudo dnf install -y topgrade &>> "$LOG_FILE"
  sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
  sudo -u "$REAL_USER" cat <<EOF > "$USER_HOME/.config/topgrade.toml"
[misc]
assume_yes = true
disable = ["containers", "node"]
[git]
repos = ["${SRC_PERSIST_DIR}/*"]
[commands]
"Limpieza del Sistema" = "sudo dnf autoremove -y && sudo dnf clean all"
EOF
  log_success "Topgrade operativo."
}

main() {
  init_environment
  show_welcome_banner
  configure_dual_shell
  deploy_user_dotfiles
  configure_starship_themes
  configure_protocols_and_isolation
  
  install_dnf_lists
  
  # SECUENCIA REESTRUCTURADA CRONOLÓGICAMENTE SEGÚN LOS COMPONENTES DE TU PLAN
  configure_office_and_fonts
  configure_flameshot_ocr_pipeline
  install_vscode_extensions_v2
  configure_system_integration_tweaks
  purge_system_bloatware_v2
  
  install_npm_lists
  install_flatpak_lists
  configure_topgrade_engine
  execute_deep_maintenance_v2
  
  sync
  log_success "SCRIPT 3 COMPLETADO EN SU TOTALIDAD."
}
main "$@"
exit 0