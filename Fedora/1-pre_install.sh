#!/bin/bash

# Script de Post-Instalación para Fedora 42
# Autor: Modificado y optimizado
# Versión: 2.0

# Variables globales
LOG_FILE="$HOME/fedora_post_install.log"
ERROR_COUNT=0

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con formato
show_message() {
    local level=$1
    local message=$2
    local date_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            echo "[$date_time] [INFO] $message" >> "$LOG_FILE"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[✓]${NC} $message"
            echo "[$date_time] [SUCCESS] $message" >> "$LOG_FILE"
            ;;
        "WARNING")
            echo -e "${YELLOW}[⚠]${NC} $message"
            echo "[$date_time] [WARNING] $message" >> "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[✗]${NC} $message"
            echo "[$date_time] [ERROR] $message" >> "$LOG_FILE"
            ((ERROR_COUNT++))
            ;;
        "PHASE")
            echo -e "\n${GREEN}===== $message =====${NC}"
            echo -e "\n[$date_time] ===== $message =====" >> "$LOG_FILE"
            ;;
    esac
}

# Función para manejar errores
check_error() {
    local exit_code=$?
    local error_msg="$1"
    local fatal="${2:-false}"  # Si es fatal, termina el script
    
    if [ $exit_code -ne 0 ]; then
        show_message "ERROR" "$error_msg (Código: $exit_code)"
        if [ "$fatal" = "true" ]; then
            show_message "ERROR" "Error fatal. Abortando script."
            exit 1
        fi
        return 1
    fi
    return 0
}

# Crea el archivo de log con encabezado
init_log() {
    echo "===================================================" > "$LOG_FILE"
    echo "Post-Instalación Fedora 42 - $(date)" >> "$LOG_FILE"
    echo "===================================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    show_message "INFO" "Iniciando proceso de post-instalación para Fedora 42"
    show_message "INFO" "Log disponible en: $LOG_FILE"
}

# Función para ejecutar comandos con sudo sin pedir contraseña repetidamente
run_sudo() {
    sudo -n true 2>/dev/null || {
        show_message "INFO" "Se necesitan privilegios de administrador para continuar"
        sudo -v || {
            show_message "ERROR" "No se pudieron obtener privilegios de administrador" "true"
            exit 1
        }
    }
    
    # Mantener sudo activo
    (
        while true; do
            sudo -n true
            sleep 50
        done
    ) &
    SUDO_PID=$!
    
    # Asegurarse de matar el proceso cuando termine el script
    trap "kill -9 $SUDO_PID" EXIT
}

# Función para configurar DNF
configure_dnf() {
    show_message "PHASE" "Configurando DNF para optimizar rendimiento"
    
    # Asegurar que el reloj esté en UTC
    sudo timedatectl set-local-rtc '0' &>/dev/null || show_message "WARNING" "No se pudo configurar timedatectl"

    # Configuración optimizada de DNF
    local DNF_CONF_CONTENT="[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
keepcache=True
deltarpm=True"

    echo "$DNF_CONF_CONTENT" | sudo tee /etc/dnf/dnf.conf > /dev/null
    check_error "No se pudo configurar /etc/dnf/dnf.conf" || return 1
    
    show_message "INFO" "Limpiando caché de DNF y actualizando sistema..."
    
    # Actualizar el sistema silenciosamente pero mostrando progreso
    sudo dnf clean all -q
    sudo dnf update -y --quiet
    sudo dnf upgrade -y --quiet
    
    if check_error "Error al actualizar o actualizar el sistema"; then
        show_message "SUCCESS" "Sistema actualizado correctamente"
    fi
}

# Función para configurar DNF Automatic
configure_dnf_automatic() {
    show_message "PHASE" "Configurando actualizaciones automáticas con DNF Automatic"
    
    show_message "INFO" "Instalando paquetes necesarios..."
    sudo dnf install -y --quiet dnf-automatic dnf-plugins-extras-tracer
    if ! check_error "No se pudieron instalar los paquetes necesarios"; then
        return 1
    fi
    
    show_message "INFO" "Configurando DNF Automatic para actualizaciones de seguridad..."
    
    # Configurar para aplicar solo actualizaciones de seguridad automáticamente
    sudo sed -i '/^upgrade_type/ s/default/security/' /etc/dnf/automatic.conf
    sudo sed -i '/^apply_updates/ s/no/yes/' /etc/dnf/automatic.conf
    check_error "No se pudo configurar automatic.conf" || return 1
    
    # Instalar script para reinicio automático después de actualizaciones
    if [ ! -d /usr/local/src/dnf-automatic-restart ]; then
        show_message "INFO" "Descargando herramienta de reinicio automático..."
        sudo mkdir -p /usr/local/src
        sudo git clone --quiet https://github.com/agross/dnf-automatic-restart.git /usr/local/src/dnf-automatic-restart
        check_error "No se pudo clonar el repositorio dnf-automatic-restart" || {
            show_message "WARNING" "Continuando sin el reinicio automático"
        }
    fi
    
    if [ -d /usr/local/src/dnf-automatic-restart ]; then
        sudo ln -sf /usr/local/src/dnf-automatic-restart/dnf-automatic-restart /usr/local/sbin/dnf-automatic-restart
        sudo systemctl enable dnf-automatic-install.timer
        
        # Configurar servicio para reinicio automático
        sudo mkdir -p /etc/systemd/system/dnf-automatic-install.service.d
        echo "[Service]" | sudo tee /etc/systemd/system/dnf-automatic-install.service.d/restart.conf > /dev/null
        echo "ExecStartPost=/usr/local/sbin/dnf-automatic-restart -d" | sudo tee -a /etc/systemd/system/dnf-automatic-install.service.d/restart.conf > /dev/null
        
        sudo systemctl daemon-reload
        check_error "No se pudo configurar el servicio de reinicio automático" || {
            show_message "WARNING" "La configuración del reinicio automático falló, pero continuando"
        }
    fi
    
    show_message "SUCCESS" "DNF Automatic configurado correctamente"
}

# Función para cambiar el nombre del host
change_hostname() {
    show_message "PHASE" "Cambiando nombre del sistema"
    
    # Hacer copia de seguridad de bashrc
    cp ~/.bashrc ~/.bashrc_original 2>/dev/null || show_message "WARNING" "No se pudo hacer copia de seguridad de .bashrc"
    
    # Preguntar por el nombre nuevo
    echo -n "Introduce el nuevo nombre para el sistema (deja en blanco para mantener el actual): "
    read -r new_hostname
    
    if [ -n "$new_hostname" ]; then
        sudo hostnamectl set-hostname "$new_hostname"
        check_error "No se pudo cambiar el nombre del sistema" || return 1
        
        show_message "SUCCESS" "El nombre del sistema ha sido cambiado a: $new_hostname"
        sudo systemctl restart systemd-hostnamed &>/dev/null
    else
        show_message "INFO" "Se mantiene el nombre actual del sistema"
    fi
}

# Función para configurar repositorios
configure_repositories() {
    show_message "PHASE" "Configurando repositorios adicionales"
    
    show_message "INFO" "Instalando repositorios de Fedora Workstation..."
    sudo dnf -y --quiet install fedora-workstation-repositories
    check_error "No se pudieron instalar los repositorios de Fedora Workstation" || show_message "WARNING" "Continuando sin los repositorios Workstation"
    
    show_message "INFO" "Instalando repositorios RPM Fusion (Free y NonFree)..."
    sudo dnf -y --quiet install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    
    if check_error "No se pudieron instalar los repositorios RPM Fusion"; then
        show_message "SUCCESS" "Repositorios RPM Fusion instalados correctamente"
    else
        show_message "WARNING" "Continuando sin los repositorios RPM Fusion"
    fi
    
    show_message "INFO" "Actualizando caché de repositorios..."
    sudo dnf clean all -q
    sudo dnf makecache --refresh -q
    sudo dnf update -y -q
    sudo dnf upgrade -y -q
    sudo dnf -y -q group upgrade core
    
    show_message "SUCCESS" "Repositorios configurados y actualizados"
}

# Función para instalar paquetes esenciales
install_essential_packages() {
    show_message "PHASE" "Instalando paquetes esenciales"
    
    # Primera ronda de paquetes fundamentales
    show_message "INFO" "Instalando herramientas de desarrollo y paquetes base..."
    sudo dnf install -y --skip-unavailable --skip-broken @development-tools git
    check_error "Algunos paquetes de desarrollo no se pudieron instalar" || show_message "WARNING" "Algunos paquetes de desarrollo no pudieron instalarse"
    
    # Segunda ronda con más paquetes
    show_message "INFO" "Instalando utilidades esenciales del sistema..."
    sudo dnf install -y --skip-unavailable --skip-broken \
        util-linux-user \
        dnf-plugins-core \
        openssl \
        finger \
        dos2unix \
        nano \
        sed \
        sudo \
        numlockx \
        wget \
        curl \
        git \
        nodejs \
        cargo \
        hunspell-es \
        cmake \
        gcc-c++ \
        cabextract \
        xorg-x11-font-utils \
        fontconfig \
        btrfs* \
        lzo \
        timeshift

    if check_error "Algunos paquetes esenciales no se pudieron instalar"; then
        show_message "SUCCESS" "Paquetes esenciales instalados correctamente"
    else
        show_message "WARNING" "Algunos paquetes esenciales no pudieron instalarse"
    fi
}

# Función para configurar repositorios Flatpak
configure_flatpak_repositories() {
    show_message "PHASE" "Configurando repositorios Flatpak"
    
    show_message "INFO" "Instalando Flatpak..."
    sudo dnf -y --quiet install flatpak
    check_error "No se pudo instalar Flatpak" || return 1
    
    show_message "INFO" "Agregando repositorios Flatpak..."
    
    # Agregar repositorios
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &>/dev/null
    sudo flatpak remote-add --if-not-exists elementary https://flatpak.elementary.io/repo.flatpakrepo &>/dev/null
    sudo flatpak remote-add --if-not-exists kde https://distribute.kde.org/kdeapps.flatpakrepo &>/dev/null
    sudo flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org &>/dev/null
    
    # Configurar prioridades
    sudo flatpak remote-modify --system --prio=1 kde &>/dev/null || show_message "WARNING" "No se pudo configurar prioridad de KDE"
    sudo flatpak remote-modify --system --prio=2 flathub &>/dev/null || show_message "WARNING" "No se pudo configurar prioridad de Flathub"
    sudo flatpak remote-modify --system --prio=3 elementary &>/dev/null || show_message "WARNING" "No se pudo configurar prioridad de Elementary"
    sudo flatpak remote-modify --system --prio=4 fedora &>/dev/null || show_message "WARNING" "No se pudo configurar prioridad de Fedora"
    
    show_message "SUCCESS" "Repositorios Flatpak configurados correctamente"
}

# Función para configurar ZSWAP
configure_zswap() {
    show_message "PHASE" "Configurando ZSWAP para mejor rendimiento del sistema"
    
    show_message "INFO" "Eliminando zram-generator si existe..."
    sudo dnf remove -y zram-generator &>/dev/null
    
    show_message "INFO" "Actualizando sistema antes de configurar ZSWAP..."
    sudo dnf update -y -q
    
    show_message "INFO" "Habilitando algoritmo de compresión lz4hc..."
    sudo modprobe lz4hc &>/dev/null
    if ! check_error "No se pudo cargar el módulo lz4hc"; then
        show_message "WARNING" "Continuando sin optimización de ZSWAP"
        return 1
    fi
    
    # Añadir lz4hc a dracut para initramfs
    show_message "INFO" "Configurando dracut para ZSWAP..."
    sudo mkdir -p /etc/dracut.conf.d
    echo 'add_drivers+="lz4hc"' | sudo tee /etc/dracut.conf.d/lz4hc.conf > /dev/null
    
    show_message "INFO" "Regenerando initramfs (esto puede tardar unos minutos)..."
    sudo dracut --regenerate-all --force &>/dev/null
    check_error "No se pudo regenerar initramfs" || {
        show_message "WARNING" "Error al regenerar initramfs, pero continuando"
    }
    
    # Configurar ZSWAP
    echo "lz4hc" | sudo tee /sys/module/zswap/parameters/compressor &>/dev/null
    
    # Calcular parámetros basados en RAM
    show_message "INFO" "Optimizando ZSWAP según memoria del sistema..."
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ $total_ram -le 4 ]; then
        swappiness=60
        zswap_max_pool=40
        vfs_cache_pressure=50
    elif [ $total_ram -le 12 ]; then
        swappiness=40
        zswap_max_pool=33
        vfs_cache_pressure=50
    elif [ $total_ram -le 20 ]; then
        swappiness=30
        zswap_max_pool=25
        vfs_cache_pressure=50
    elif [ $total_ram -le 32 ]; then
        swappiness=20
        zswap_max_pool=20
        vfs_cache_pressure=75
    else
        swappiness=10
        zswap_max_pool=20
        vfs_cache_pressure=75
    fi
    
    # Configurar sysctl para ZSWAP
    sysctl_conf="/etc/sysctl.d/99-zswap.conf"
    echo "vm.swappiness=$swappiness" | sudo tee "$sysctl_conf" > /dev/null
    echo "vm.vfs_cache_pressure=$vfs_cache_pressure" | sudo tee -a "$sysctl_conf" > /dev/null
    sudo sysctl -p "$sysctl_conf" &>/dev/null
    
    # Configurar GRUB para ZSWAP
    show_message "INFO" "Configurando GRUB para ZSWAP..."
    grub_file="/etc/default/grub"
    sudo cp "$grub_file" "$grub_file.bak"
    
    # Añadir parámetros de ZSWAP a GRUB
    sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ zswap.enabled=1 zswap.max_pool_percent='"$zswap_max_pool"' zswap.zpool=z3fold zswap.compressor=lz4hc"/' "$grub_file"
    
    # Actualizar GRUB
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null
    check_error "No se pudo actualizar GRUB" || {
        show_message "WARNING" "Error al actualizar GRUB, pero continuando"
    }
    
    # Crear script para monitorear ZSWAP
    script_file="/usr/local/bin/zswap-monitor"
    script_content='#!/bin/bash
MDL=/sys/module/zswap
DBG=/sys/kernel/debug/zswap
PAGE=$(( $(cat $DBG/stored_pages 2>/dev/null || echo 0) * 4096 ))
POOL=$(( $(cat $DBG/pool_total_size 2>/dev/null || echo 0) ))
Show(){
    printf "========\n$1\n========\n"
    grep -R . $2 2>&1 | sed "s|.*/||"
}
Show "ZSWAP Settings" $MDL
Show "ZSWAP Statistics" $DBG
printf "\nCompression ratio: "
[ $POOL -gt 0 ] && {
    echo "scale=3; $PAGE / $POOL" | bc
} || echo "ZSWAP disabled"'

    echo "$script_content" | sudo tee "$script_file" > /dev/null
    sudo chmod +x "$script_file"
    
    show_message "SUCCESS" "ZSWAP configurado correctamente"
    show_message "INFO" "Puedes ver estadísticas de ZSWAP con: sudo zswap-monitor"
}

# Función para configurar seguridad
configure_security() {
    show_message "PHASE" "Configurando seguridad del sistema"
    
    # Crear snapshot de seguridad
    show_message "INFO" "Creando snapshot de seguridad con Timeshift..."
    sudo timeshift --create --comments "pre-security-update" --tags D &>/dev/null || show_message "WARNING" "No se pudo crear snapshot con Timeshift"
    
    # Instalar paquetes de seguridad
    show_message "INFO" "Instalando paquetes de seguridad..."
    sudo dnf install -y --skip-unavailable --skip-broken \
        resolvconf \
        firewalld \
        firewall-config \
        selinux-policy \
        selinux-policy-targeted \
        policycoreutils \
        policycoreutils-python-utils \
        setools \
        npm
    
    # Habilitar firewalld
    show_message "INFO" "Habilitando firewall..."
    sudo systemctl enable --now firewalld &>/dev/null
    check_error "No se pudo habilitar firewalld" || show_message "WARNING" "Error al activar firewalld, pero continuando"
    
    # Configurar SELinux
    show_message "INFO" "Configurando SELinux en modo enforcing..."
    sudo sed -i 's/SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
    
    # Configurar firewall
    show_message "INFO" "Configurando reglas de firewall..."
    sudo firewall-cmd --set-default-zone=FedoraWorkstation &>/dev/null
    sudo firewall-cmd --complete-reload &>/dev/null
    
    # Cerrar todos los puertos y luego abrir solo los necesarios
    sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1-65535/tcp --permanent &>/dev/null
    sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1-65535/udp --permanent &>/dev/null
    
    # Obtener puertos habilitados y eliminarlos
    enabled_ports=$(sudo firewall-cmd --zone=FedoraWorkstation --list-ports 2>/dev/null)
    if [ -n "$enabled_ports" ]; then
        read -r -a ports_array <<< "$enabled_ports"
        for port in "${ports_array[@]}"; do
            sudo firewall-cmd --zone=FedoraWorkstation --remove-port="$port" --permanent &>/dev/null
        done
    fi
    
    sudo firewall-cmd --reload &>/dev/null
    
    # Configurar servicios permitidos
    sudo firewall-cmd --add-interface=lo --zone=FedoraWorkstation --permanent &>/dev/null
    
    # Servicios y puertos básicos a habilitar
    declare -a services=(
        "http"          # Puerto 80/tcp
        "https"         # Puerto 443/tcp
        "ssh"           # Puerto 22/tcp
        "samba"         # Puertos para compartir archivos
        "dns"           # DNS
        "dhcpv6-client" # Cliente DHCPv6
        "ping"          # ICMP
    )
    
    declare -a ports=(
        "22/tcp"        # SSH
        "631/tcp"       # CUPS (impresión)
        "1194/udp"      # OpenVPN
        "5353/udp"      # mDNS
        "33434-33523/udp" # Traceroute
    )
    
    show_message "INFO" "Habilitando servicios esenciales en firewall..."
    for service in "${services[@]}"; do
        sudo firewall-cmd --add-service="$service" --zone=FedoraWorkstation --permanent &>/dev/null
    done
    
    show_message "INFO" "Habilitando puertos esenciales en firewall..."
    for port in "${ports[@]}"; do
        sudo firewall-cmd --add-port="$port" --zone=FedoraWorkstation --permanent &>/dev/null
    done
    
    sudo firewall-cmd --reload &>/dev/null
    
    # Configurar SELinux para firewalld
    show_message "INFO" "Ajustando SELinux para firewalld..."
    sudo semanage permissive -a firewalld_t &>/dev/null
    
    # Configurar DNS seguros
    show_message "INFO" "Configurando servidores DNS seguros..."
    sudo mkdir -p '/etc/systemd/resolved.conf.d'
    echo -e "[Resolve]\nDNS=94.140.14.14 94.140.15.15 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4\nDNSOverTLS=yes" \
        | sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf > /dev/null
    
    sudo systemctl restart systemd-resolved &>/dev/null
    
    # Instalar y configurar bloqueo de anuncios
    show_message "INFO" "Configurando bloqueador de anuncios y trackers..."
    sudo npm install -g hblock &>/dev/null
    hblock &>/dev/null
    
    show_message "SUCCESS" "Configuración de seguridad completada"
}

# Función para configurar soporte BTRFS y Timeshift
# Función para configurar subvolúmenes BTRFS y actualizar /etc/fstab
configure_btrfs_volumes() {
    show_message "PHASE" "Configurando subvolúmenes BTRFS"

    show_message "INFO" "Verificando sistema de archivos..."
    local FS_TYPE
    FS_TYPE=$(df -T / | awk 'NR==2 {print $2}')
    if [[ "$FS_TYPE" != "btrfs" ]]; then
        show_message "WARNING" "El sistema raíz no está en BTRFS. Omitiendo configuración BTRFS."
        return 0
    fi

    show_message "INFO" "Instalando herramientas necesarias..."
    sudo dnf install -y --skip-unavailable --skip-broken btrfs-progs inotify-tools &>/dev/null

    show_message "INFO" "Configurando subvolúmenes en fstab..."

    get_uuid() {
        local mount_point=$1
        grep -E "${mount_point}\s+btrfs\s+" "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p'
    }

    output_file="/etc/fstab.new"
    cp /etc/fstab /etc/fstab.old
    cp /etc/fstab $output_file

    ROOT_UUID=$(get_uuid "/")
    HOME_UUID=$(get_uuid "/home")
    VAR_UUID=$(get_uuid "/var")
    VAR_LOG_UUID=$(get_uuid "/var/log")
    SNAPSHOT_UUID=$(get_uuid "/.snapshots")

    if [ -n "$ROOT_UUID" ]; then
        sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} / btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@ 0 0|" $output_file
    fi
    if [ -n "$HOME_UUID" ]; then
        sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@home 0 0|" $output_file
    fi
    if [ -n "$VAR_UUID" ]; then
        sudo sed -i -E "s|UUID=.*\s+/var\s+btrfs.*|UUID=${VAR_UUID} /var btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@var 0 0|" $output_file
    fi
    if [ -n "$VAR_LOG_UUID" ]; then
        sudo sed -i -E "s|UUID=.*\s+/var/log\s+btrfs.*|UUID=${VAR_LOG_UUID} /var/log btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@log 0 0|" $output_file
    fi
    if [ -n "$SNAPSHOT_UUID" ]; then
        sudo sed -i -E "s|UUID=.*\s+/.snapshots\s+btrfs.*|UUID=${SNAPSHOT_UUID} /.snapshots btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@snapshots 0 0|" $output_file
    fi

    sudo cp $output_file /etc/fstab

    show_message "INFO" "Aplicando compresión LZO a subvolúmenes..."
    sudo btrfs filesystem defragment / -r -clzo &>/dev/null
    sudo btrfs balance start -m / &>/dev/null
}

instalar_grub_btrfs() {
     
    show_message "INFO" "Habilitando repositorio y actualizando sistema..."
    sudo dnf copr enable -y kylegospo/grub-btrfs || error "No se pudo habilitar el repositorio COPR."
    sudo dnf update -y || error "Fallo al actualizar el sistema."

    show_message "INFO" "Instalando grub-btrfs y extensiones..."
    sudo dnf install -y grub-btrfs  || error "Fallo al instalar grub-btrfs o sus extensiones."
    sudo dnf install -y grub-btrfs-timeshift  || error "Fallo al instalar grub-btrfs o sus extensiones."
    

    show_message "INFO" "Configurando GRUB para detectar snapshots..."
    mkdir -p /etc/default/grub-btrfs || error "No se pudo crear el directorio de configuración."
    cat > /etc/default/grub-btrfs/config <<EOF
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig
GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check
GRUB_BTRFS_SUBMENUNAME="Snapshots BTRFS"
GRUB_BTRFS_SNAPSHOT_FORMAT="%Y-%m-%d %H:%M | %c
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rootflags=subvol=@ quiet"
EOF

    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    show_message "INFO" "Habilitando servicios grub-btrfs..."
    systemctl enable --now grub-btrfsd.service || error "Fallo al habilitar grub-btrfsd.service"
    systemctl start --now grub-btrfsd.service || error "Fallo al habilitar grub-btrfsd.service"

    show_message "INFO" "Configurando monitorización systemd para snapshots Timeshift..."
    mkdir -p /etc/systemd/system/grub-btrfs.path.d || error "No se pudo crear directorio para overrides."
    sudo tee /etc/systemd/system/grub-btrfs.path > /dev/null <<'EOF'

[Unit]
Description=Monitors Timeshift snapshots in /run/timeshift/%i/backup
DefaultDependencies=no
BindsTo=run-timeshift-%i.mount

[Path]
PathModified=/run/timeshift/%i/backup/timeshift-btrfs/snapshots

[Install]
WantedBy=run-timeshift-%i.mount
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    # Habilitar para todas las instancias posibles
    systemctl enable --now grub-btrfs@*.path || error "Fallo al iniciar el servicio path"
    systemctl enable --now grub-btrfs.path || error "Fallo al iniciar el servicio path"
    systemctl start --now grub-btrfs.path || error "Fallo al habilitar el servicio path"

    systemctl enable --now grub-btrfsd@*.service || error "Fallo al habilitar grub-btrfsd.service"
    systemctl enable --now grub-btrfsd.service || error "Fallo al habilitar grub-btrfsd.service"
    systemctl start --now grub-btrfsd.service || error "Fallo al habilitar grub-btrfsd.service"
    
    show_message "SUCCESS" "Systemd configurado para rutas dinámicas: /run/timeshift/*/backup"

    show_message "INFO" "Configurando Timeshift para snapshots automáticos..."
    sudo mkdir -p /.snapshots

    timeshift --btrfs --snapshot-device "$(findmnt -no SOURCE /)" --snapshot-dir /.snapshots || error "Fallo al configurar Timeshift."
    timeshift --create --comments "Snapshot inicial" || error "Fallo al crear snapshot inicial."
 
    cat > /etc/timeshift.json <<EOF
{
  "backup_device_uuid" : "$(findmnt -no UUID /)",
  "snapshot_dir" : "/.snapshots",
  "snapshot_name" : "timeshift-btrfs",
  "mode" : "btrfs",
  "schedule_daily" : true,
  "count_daily" : 5,
  "schedule_weekly" : true,
  "count_weekly" : 3,
  "schedule_monthly" : true,
  "count_monthly" : 2
}
EOF

     show_message "SUCCESS" "grub-btrfs y Timeshift instalados y configurados correctamente."
}


main() {
    # Inicializar registro y verificar privilegios
    init_log
    run_sudo
    
    # Configuración básica del sistema
    #configure_dnf
    #configure_dnf_automatic
    #change_hostname
    
    # Instalación y configuración de repositorios y paquetes
    #configure_repositories
    #install_essential_packages
    #configure_flatpak_repositories
    
    # Optimizaciones del sistema
    #configure_zswap
    configure_btrfs_volumes
    instalar_grub_btrfs
    
    
    # Seguridad
    #configure_security
    
    # Si existe la función update_firmware, llamarla también
    if type update_firmware &>/dev/null; then
        update_firmware
    fi
    
    # Mostrar resumen final
    show_message "PHASE" "Proceso de post-instalación completado"
    
    if [ $ERROR_COUNT -gt 0 ]; then
        show_message "WARNING" "Se encontraron $ERROR_COUNT errores durante la instalación"
        show_message "INFO" "Revisa el archivo de log para más detalles: $LOG_FILE"
    else
        show_message "SUCCESS" "¡Instalación completada sin errores!"
    fi
    
    show_message "INFO" "Se recomienda reiniciar el sistema para aplicar todos los cambios"
}

# Ejecutar la función principal
main "$@"
