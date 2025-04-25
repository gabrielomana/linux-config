#!/bin/bash

# Script de Post-instalación para Fedora 42
# Este script realiza la configuración post-instalación de manera autónoma
# con gestión de errores y registro de actividades detallado.

# ================ VARIABLES GLOBALES ================
SCRIPT_DIR="$(pwd)"
EXTRA_APPS_LIST="${SCRIPT_DIR}/sources/lists/extra_apps.list"
USER_HOME="$HOME"
LOG_FILE="${USER_HOME}/fedora_post_install.log"
ERROR_COUNT=0
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# ================ FUNCIONES DE UTILIDAD ================
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

print_message() {
    local level="$1"
    local message="$2"
    local color=""
    
    case "$level" in
        "INFO")
            color="\033[0;34m" # Azul
            ;;
        "ERROR")
            color="\033[0;31m" # Rojo
            ;;
        "SUCCESS")
            color="\033[0;32m" # Verde
            ;;
        *)
            color="\033[0m" # Sin color
            ;;
    esac
    
    echo -e "${color}[$level] $message\033[0m"
    log "$level" "$message"
}

execute_command() {
    local command="$1"
    local description="$2"
    
    print_message "INFO" "Ejecutando: $description"
    
    # Ejecutar comando y capturar salida y código de retorno
    output=$(eval "$command" 2>&1)
    local status=$?
    
    if [ $status -eq 0 ]; then
        print_message "SUCCESS" "$description completado correctamente"
        log "OUTPUT" "$output"
    else
        print_message "ERROR" "Error al ejecutar: $description"
        log "ERROR_DETAIL" "$output"
        ((ERROR_COUNT++))
    fi
    
    return $status
}

check_dependencies() {
    print_message "INFO" "Verificando dependencias..."
    
    local dependencies=("git" "wget" "unzip" "cmake" "dnf")
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_message "INFO" "Instalando dependencias faltantes: ${missing_deps[*]}"
        execute_command "sudo dnf install -y ${missing_deps[*]}" "Instalación de dependencias"
    else
        print_message "SUCCESS" "Todas las dependencias están instaladas"
    fi

}

add_repositories (){

execute_command "sudo dnf install dnf-plugins-core" "dnf-plugins-core instalado correctamente"
execute_command "sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo" "Repositorio de Brave añadido correctamente"
execute_command "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc" "Repositorio Microsoft"
execute_command "echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null"
execute_command "sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf copr enable lilay/topgrade -y || true
sudo dnf copr enable refi64/webapp-manager -y || true



dnf check-update

}

setup_log_file() {
    # Crear el archivo de log con encabezado
    echo "===============================================================" > "$LOG_FILE"
    echo "    LOG DE POST-INSTALACIÓN FEDORA 42 - $TIMESTAMP" >> "$LOG_FILE"
    echo "===============================================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    print_message "INFO" "Archivo de log creado en $LOG_FILE"
}

# ================ MÓDULOS DE INSTALACIÓN ================
install_konsole_and_dotfiles() {
    print_message "INFO" "=== INICIANDO INSTALACIÓN DE KONSOLE Y DOTFILES ==="
    
   
    # Instalar FastFetch
    local fastfetch_path="$SCRIPT_DIR/fastfetch/"
    
    execute_command "sudo rm -rf $fastfetch_path" "Limpieza de instalación previa de fastfetch"
    execute_command "sudo git clone https://github.com/fastfetch-cli/fastfetch.git $fastfetch_path" "Clonación de repositorio fastfetch"
    
    execute_command "cd $fastfetch_path && sudo mkdir -p build && cd build && sudo cmake .. && sudo cmake --build . --target fastfetch --target flashfetch" "Compilación de fastfetch"
    execute_command "sudo cp $fastfetch_path/build/fastfetch $fastfetch_path/build/flashfetch /usr/bin/" "Instalación de fastfetch"
    
    # Configurar FastFetch
    execute_command "cd ${SCRIPT_DIR} && fastfetch --gen-config-force" "Generación de configuración de fastfetch"
    execute_command "mkdir -p ~/.config/fastfetch && cp -r ${SCRIPT_DIR}/dotfiles/fastfetch_config.jsonc ~/.config/fastfetch/config.jsonc" "Copia de configuración de fastfetch"
    
    # Instalar temas de Konsole
    execute_command "sudo wget -q https://github.com/gabrielomana/color_schemes/raw/main/konsole.zip -O /tmp/konsole.zip" "Descarga de temas de Konsole"
    execute_command "sudo unzip -o /tmp/konsole.zip -d /tmp/" "Descompresión de temas de Konsole"
    execute_command "sudo cp -rf /tmp/konsole/* /usr/share/konsole/" "Instalación de temas de Konsole"
    execute_command "sudo rm -rf /tmp/konsole/ /tmp/konsole.zip" "Limpieza de archivos temporales"
    
    # Copiar archivos de configuración
    execute_command "mkdir -p ~/.config/neofetch" "Creación de directorio para neofetch"
    execute_command "cp -r ${SCRIPT_DIR}/dotfiles/neofetch.conf ~/.config/neofetch/config.conf" "Configuración de neofetch"
    execute_command "cp -r ${SCRIPT_DIR}/dotfiles/topgrade.toml ~/.config/topgrade.toml" "Configuración de topgrade"
    execute_command "cp -r ${SCRIPT_DIR}/dotfiles/.nanorc ~/.nanorc" "Configuración de nano"
    execute_command "mkdir -p ~/.local/share/konsole && cp -r ${SCRIPT_DIR}/dotfiles/konsole.profile ~/.local/share/konsole/konsole.profile" "Perfil de Konsole"
    execute_command "cp -r ${SCRIPT_DIR}/dotfiles/konsolerc ~/.config/konsolerc" "Configuración de Konsole"
    
    print_message "SUCCESS" "=== FINALIZADA INSTALACIÓN DE KONSOLE Y DOTFILES ==="
}

install_extra_apps() {
    print_message "INFO" "=== INICIANDO INSTALACIÓN DE APLICACIONES ADICIONALES ==="
    
    if [ -f "$EXTRA_APPS_LIST" ]; then
        print_message "INFO" "Leyendo lista de aplicaciones desde $EXTRA_APPS_LIST"
        
        while IFS= read -r app || [[ -n "$app" ]]; do
            # Ignorar líneas en blanco o comentarios
            [[ -z "$app" || "$app" =~ ^# ]] && continue
            
            execute_command "sudo dnf install -y $app" "Instalación de $app"
        done < "$EXTRA_APPS_LIST"
    else
        print_message "ERROR" "Archivo de lista de aplicaciones no encontrado: $EXTRA_APPS_LIST"
        ((ERROR_COUNT++))
    fi
    
    print_message "SUCCESS" "=== FINALIZADA INSTALACIÓN DE APLICACIONES ADICIONALES ==="
}

system_cleanup() {
    print_message "INFO" "=== INICIANDO LIMPIEZA Y ACTUALIZACIÓN DEL SISTEMA ==="
    
    # Limpieza con BleachBit
    execute_command "sudo bleachbit -c system.tmp system.trash system.cache system.localizations system.desktop_entry" "Limpieza del sistema con BleachBit"
    
    # Actualización del sistema
    execute_command "sudo dnf -y update" "Actualización inicial del sistema"
    execute_command "sudo dnf -y install dnf-plugins-core --exclude=zram*" "Instalación de plugins DNF"
    execute_command "sudo dnf remove --duplicates -y" "Eliminación de paquetes duplicados"
    execute_command "sudo dnf -y distro-sync" "Sincronización de distribución"
    execute_command "sudo dnf -y check" "Verificación de dependencias"
    execute_command "sudo dnf -y autoremove" "Eliminación de paquetes innecesarios"
    execute_command "sudo dnf -y update --refresh" "Actualización con refresco de caché"
    execute_command "sudo dnf -y update --best --allowerasing" "Actualización final del sistema"
    
    print_message "SUCCESS" "=== FINALIZADA LIMPIEZA Y ACTUALIZACIÓN DEL SISTEMA ==="
}

install_zsh() {
    print_message "INFO" "=== INICIANDO INSTALACIÓN DE ZSH, OH-MY-ZSH Y STARSHIP ==="
    
    # Importar funciones específicas para ZSH
    if [ -f "${SCRIPT_DIR}/sources/functions/zsh_starship" ]; then
        # Primero cargar las funciones
        . "${SCRIPT_DIR}/sources/functions/zsh_starship"
        
        # Si existe la función install_ZSH, ejecutarla
        if type install_ZSH &>/dev/null; then
            execute_command "install_zsh_main" "Instalación de ZSH y complementos"
        else
            print_message "ERROR" "Función install_ZSH_User no encontrada en el archivo importado"
            ((ERROR_COUNT++))
        fi
    else
        print_message "ERROR" "Archivo de funciones ZSH no encontrado: ${SCRIPT_DIR}/sources/functions/zsh_starship"
        ((ERROR_COUNT++))
    fi
    
    print_message "SUCCESS" "=== FINALIZADA INSTALACIÓN DE ZSH, OH-MY-ZSH Y STARSHIP ==="
}

# ================ PROGRAMA PRINCIPAL ================
main() {
    # Inicializar archivo de log
    setup_log_file
    
    # Verificar dependencias iniciales
    check_dependencies
    add_repositories
    
    # Importar funciones adicionales si existen
    if [ -f "${SCRIPT_DIR}/sources/functions/functions" ]; then
        . "${SCRIPT_DIR}/sources/functions/functions"
        print_message "INFO" "Funciones adicionales importadas correctamente"
    else
        print_message "ERROR" "Archivo de funciones adicionales no encontrado: ${SCRIPT_DIR}/sources/functions/functions"
        ((ERROR_COUNT++))
    fi
    
    # Ejecutar módulos en secuencia
    install_konsole_and_dotfiles
    install_extra_apps
    system_cleanup
    install_zsh
    
    # Mostrar resumen final
    echo ""
    echo "==============================================================="
    if [ $ERROR_COUNT -eq 0 ]; then
        print_message "SUCCESS" "INSTALACIÓN COMPLETADA SIN ERRORES"
    else
        print_message "ERROR" "INSTALACIÓN COMPLETADA CON $ERROR_COUNT ERRORES"
        print_message "INFO" "Por favor revise el archivo de log en $LOG_FILE para más detalles"
    fi
    echo "==============================================================="
    
    # Preguntar si desea reiniciar
    echo ""
    read -p "¿Desea reiniciar el sistema ahora? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_message "INFO" "Reiniciando el sistema..."
        execute_command "sudo reboot" "Reinicio del sistema"
    else
        print_message "INFO" "Reinicio cancelado. Por favor reinicie manualmente para aplicar todos los cambios."
    fi
}

# Iniciar el script
main