#!/bin/bash

# Función para manejar errores
function check_error {
    if [ $? -ne 0 ]; then
        error_message="Error: $1"
        echo "$error_message"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $error_message" >> log.txt
        exit 1
    fi
}

# Función para configurar DNF
function configure-dnf {
    clear
    sudo timedatectl set-local-rtc '0'

    DNF_CONF_CONTENT="[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
#Speed
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
keepcache=True
deltarpm=True"

    echo "$DNF_CONF_CONTENT" | sudo tee /etc/dnf/dnf.conf > /dev/null
    check_error "Failed to configure DNF."

    sudo dnf clean all
    sudo dnf update -y
    sudo dnf upgrade -y
    check_error "Failed to update or upgrade system."
    sleep 3
}

# Función para configurar DNF Automatic
function configure-dnf-automatic {
    sudo dnf install -y dnf-automatic dnf-plugins-extras-tracer
    check_error "Failed to install dnf-automatic and tracer."

    sudo sed -i '/^upgrade_type/ s/default/security/' /etc/dnf/automatic.conf
    sudo sed -i '/^apply_updates/ s/no/yes/' /etc/dnf/automatic.conf

    sudo git clone https://github.com/agross/dnf-automatic-restart.git /usr/local/src/dnf-automatic-restart
    check_error "Failed to clone dnf-automatic-restart repository."

    sudo ln -s /usr/local/src/dnf-automatic-restart/dnf-automatic-restart /usr/local/sbin/dnf-automatic-restart
    sudo systemctl enable dnf-automatic-install.timer

    sudo mkdir -p /etc/systemd/system/dnf-automatic-install.service.d
    echo "[Service]" | sudo tee /etc/systemd/system/dnf-automatic-install.service.d/restart.conf > /dev/null
    echo "ExecStartPost=/usr/local/sbin/dnf-automatic-restart -d" | sudo tee -a /etc/systemd/system/dnf-automatic-install.service.d/restart.conf > /dev/null

    sudo systemctl daemon-reload
    echo "DNF Automatic configuration completed. The system will restart automatically if necessary to update services."
}

# Función para cambiar el nombre del host
function change-hostname {
    clear
    cp ~/.bashrc ~/.bashrc_original
    read -p "Enter the new name for the system: " new_hostname
    sudo hostnamectl set-hostname "$new_hostname"
    echo "The system name has been changed to: $new_hostname"
    sudo systemctl restart systemd-hostnamed
}

# Función para configurar repositorios
function configure-repositories {
    sudo dnf -y install fedora-workstation-repositories
    sudo dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf clean all
    sudo dnf makecache --refresh
    sudo dnf update -y
    sudo dnf upgrade -y
    sudo dnf -y group upgrade core
}

# Función para instalar paquetes esenciales
function install-essential-packages {
    sudo dnf install -y --skip-unavailable --skip-broken @development-tools git
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
}

# Función para configurar repositorios Flatpak
function configure-flatpak-repositories {
    clear
    echo "Configuring Flatpak repositories..."
    sleep 3
    sudo dnf -y install flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak remote-add --if-not-exists elementary https://flatpak.elementary.io/repo.flatpakrepo
    sudo flatpak remote-add --if-not-exists kde https://distribute.kde.org/kdeapps.flatpakrepo
    sudo flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org

    sudo flatpak remote-modify --system --prio=1 kde
    sudo flatpak remote-modify --system --prio=2 flathub
    sudo flatpak remote-modify --system --prio=3 elementary
    sudo flatpak remote-modify --system --prio=4 fedora
}

function configure-zswap {

    # Eliminar zram-generator si está instalado
    sudo dnf remove -y zram-generator
    check_error "No se pudo eliminar zram-generator."

    # Actualizar el sistema
    sudo dnf update -y
    check_error "No se pudo actualizar el sistema."

    # Habilitar lz4hc en el kernel
    sudo modprobe lz4hc
    check_error "No se pudo habilitar lz4hc en el kernel."

    # Añadir lz4hc a dracut para que esté disponible en el initramfs
    sudo mkdir -p /etc/dracut.conf.d
    echo 'add_drivers+="lz4hc"' | sudo tee /etc/dracut.conf.d/lz4hc.conf > /dev/null
    check_error "No se pudo configurar dracut."

    # Regenerar initramfs
    sudo dracut --regenerate-all --force
    check_error "No se pudo regenerar initramfs."

    # Configurar ZSWAP en el kernel
    echo "lz4hc" | sudo tee /sys/module/zswap/parameters/compressor > /dev/null
    check_error "No se pudo configurar el compresor de ZSWAP."

    # Calcular parámetros de ZSWAP basados en la RAM
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
    sudo sysctl -p "$sysctl_conf"
    check_error "No se pudo aplicar la configuración de sysctl."

    # Configurar GRUB para habilitar ZSWAP
    grub_file="/etc/default/grub"
    sudo cp "$grub_file" "$grub_file.bak"
    check_error "No se pudo hacer una copia de seguridad de GRUB."

    # Añadir parámetros de ZSWAP a GRUB
    sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ zswap.enabled=1 zswap.max_pool_percent='"$zswap_max_pool"' zswap.zpool=z3fold zswap.compressor=lz4hc"/' "$grub_file"
    check_error "No se pudo modificar GRUB."

    # Actualizar GRUB
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    check_error "No se pudo actualizar GRUB."

    # Crear script para monitorear ZSWAP
    script_file="/usr/local/bin/zswap-monitor"
    script_content='#!/bin/bash
MDL=/sys/module/zswap
DBG=/sys/kernel/debug/zswap
PAGE=$(( $(cat $DBG/stored_pages) * 4096 ))
POOL=$(( $(cat $DBG/pool_total_size) ))
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
    check_error "No se pudo crear el script de monitoreo de ZSWAP."

    # Mostrar información de ZSWAP
    sudo bash "$script_file"
}

# Función para configurar BTRFS
function set-btrfs() {
    set -euo pipefail

    echo "▶️ Post-instalación Fedora 42: Subvolúmenes BTRFS + Timeshift + grub-btrfs"

    ## Variables generales
    local MOUNT_OPTIONS="defaults,noatime,space_cache=v2,compress=lzo"
    local BTRFS_ROOT_DEV
    BTRFS_ROOT_DEV="$(findmnt -nRo SOURCE /)"
    local UUID
    UUID="$(findmnt -no UUID /)"
    local SNAPSHOT_DIR="/.snapshots"
    local FSTAB_FILE="/etc/fstab"

    ## Subvolúmenes esperados
    declare -A SUBVOLS=(
        ["/"]="@"
        ["/home"]="@home"
        ["/var"]="@var"
        ["$SNAPSHOT_DIR"]="@snapshots"
    )

    ## --- PASO 1: Instalación de herramientas necesarias --- 
    echo "🛠️ Instalando herramientas necesarias..."
    sudo dnf install -y --skip-unavailable --skip-broken btrfs-progs timeshift inotify-tools

    ## --- PASO 2: Validación y configuración de fstab ---
    echo "🧾 Verificando sistema de archivos y reconfigurando fstab..."
    local FS_TYPE
    FS_TYPE=$(df -T / | awk 'NR==2 {print $2}')
    if [[ "$FS_TYPE" != "btrfs" ]]; then
        echo "❌ Error: El sistema raíz no está en BTRFS. Abortando."
        return 1
    fi

    sudo cp -n "$FSTAB_FILE" "${FSTAB_FILE}.bak"
    sudo sed -i '/btrfs/d' "$FSTAB_FILE"

    for MOUNTPOINT in "${!SUBVOLS[@]}"; do
        local SUBVOL="${SUBVOLS[$MOUNTPOINT]}"
        echo "➕ Añadiendo $MOUNTPOINT -> subvol=$SUBVOL"
        echo "UUID=$UUID $MOUNTPOINT btrfs subvol=$SUBVOL,$MOUNT_OPTIONS 0 0" | sudo tee -a "$FSTAB_FILE" > /dev/null
    done

    ## --- PASO 3: Aplicar compresión LZO ---
    echo "🌀 Aplicando compresión LZO a subvolúmenes..."
    sudo btrfs filesystem defragment / -r -clzo

    ## --- PASO 4: Instalar grub-btrfs desde GitHub ---
    echo "🔧 Instalando grub-btrfs desde el repositorio de GitHub..."

    # Detección UEFI/BIOS para dependencias de GRUB
    if [[ -d /sys/firmware/efi ]]; then
        echo "⚙️ Modo UEFI detectado."
        sudo dnf install -y --skip-unavailable --skip-broken grub2-efi-x64 grub2-efi-bootloader
    else
        echo "⚙️ Modo BIOS detectado."
        sudo dnf install -y --skip-unavailable --skip-broken grub2-pc
    fi

    # Clonar grub-btrfs
    echo "📦 Clonando grub-btrfs..."
    sudo rm -rf /git/grub-btrfs
    sudo git clone --depth 1 https://github.com/Antynea/grub-btrfs.git /git/grub-btrfs

    # Instalar dependencias de compilación
    echo "🔧 Instalando dependencias de compilación..."
    sudo dnf install -y --skip-unavailable --skip-broken make automake gcc gcc-c++ kernel-devel inotify-tools

    # Compilar e instalar
    echo "🛠 Compilando e instalando grub-btrfs..."
    cd /git/grub-btrfs || { echo "❌ No se pudo acceder a /git/grub-btrfs"; return 1; }
    sudo make install || { echo "❌ Error al instalar grub-btrfs"; return 1; }

    # Permisos y activación
    sudo chmod +s /usr/bin/grub-btrfsd
    echo "🟢 Activando grub-btrfsd..."
    sudo systemctl enable --now grub-btrfsd.service

    # Regenerar GRUB
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    ## --- PASO 5: Timeshift ---
    echo "🧩 Configurando Timeshift..."
    [[ -d "$SNAPSHOT_DIR" ]] || sudo mkdir -p "$SNAPSHOT_DIR"
    sudo timeshift --btrfs --snapshot-device "$BTRFS_ROOT_DEV" --snapshot-dir "$SNAPSHOT_DIR" || echo "⚠️ Error al configurar Timeshift."
    sudo timeshift --create --comments "Snapshot inicial" || echo "⚠️ No se pudo crear el snapshot."

    ## --- PASO 6: Timeshift gráfico seguro ---
    if [[ -f /usr/bin/timeshift-gtk ]]; then
        echo "🔒 Configurando Timeshift GUI (pkexec)..."
        sudo mv /usr/bin/timeshift-gtk /usr/bin/timeshift-gtk-back || true
        echo -e '#!/bin/bash\n/bin/pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY /usr/bin/timeshift-gtk-back' | sudo tee /usr/bin/timeshift-gtk > /dev/null
        sudo chmod +x /usr/bin/timeshift-gtk
    else
        echo "⚠️ timeshift-gtk no encontrado. Omitiendo configuración GUI."
    fi

    ## --- Finalización ---
    echo "✅ ¡Configuración completada! Verifica:"
    echo "   - Snapshots en GRUB: sudo grep 'submenu.*Snapshots' /boot/grub2/grub.cfg"
    echo "   - Estado de grub-btrfsd: systemctl status grub-btrfsd.service"
}


#
# Función para configurar la seguridad en Fedora
function security-fedora {
    sudo timeshift --create --comments "pre-security-update" --tags D

    sudo dnf update -y

    sudo dnf install -y \
        resolvconf \
        firewalld \
        firewall-config \
        selinux-policy \
        selinux-policy-targeted \
        policycoreutils \
        policycoreutils-python-utils \
        setools \
        npm

    sudo systemctl enable --now firewalld

    sudo sed -i 's/SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

    sudo firewall-cmd --set-default-zone=FedoraWorkstation
    sudo firewall-cmd --complete-reload

    sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1-65535/tcp --permanent
    sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1-65535/udp --permanent

    enabled_ports=$(sudo firewall-cmd --zone=FedoraWorkstation --list-ports)
    read -r -a ports_array <<< "$enabled_ports"

    for port in "${ports_array[@]}"; do
        sudo firewall-cmd --zone=FedoraWorkstation --remove-port="$port" --permanent
    done

    sudo firewall-cmd --reload
    sudo firewall-cmd --add-interface=lo --zone=FedoraWorkstation --permanent
    sudo firewall-cmd --zone=FedoraWorkstation --add-service=http --permanent
    sudo firewall-cmd --zone=FedoraWorkstation --add-service=ping --permanent
    sudo firewall-cmd --zone=FedoraWorkstation --add-service=dns --permanent
    sudo firewall-cmd --zone=FedoraWorkstation --add-port=33434-33523/udp --permanent

    declare -a services=(
        "http"          # Puerto 80/tcp
        "https"         # Puerto 443/tcp
        "ssh"           # Puerto 22/tcp
        "samba"         # Puertos 137-138/udp, 139/tcp, 445/tcp
        "ftp"           # Puerto 21/tcp
        "sftp"          # Puerto 22/tcp
        "dnsmasq"       # Puerto 5353/udp
        "dhcpv6-client" # Puerto 546/udp
        "pop3"          # Puerto 110/tcp
        "pop3s"         # Puerto 995/tcp
        "imap"          # Puerto 143/tcp
        "imaps"         # Puerto 993/tcp
        "kde-connect"   # Puertos 1714 y 1715
    )

    declare -a ports=(
        "1194/udp"      # OpenVPN
        "137-138/udp"   # NetBIOS
        "631/tcp"       # CUPS
        "5353/udp"      # mDNS
        "8200/tcp"      # Plex Media Server
        "1900/udp"      # UPnP
        "8080/tcp"      # HTTP alternativo
        "3389/tcp"      # RDP
        "6881-6891/tcp" # BitTorrent
        "22/tcp"        # SSH
        "62062-62072/tcp" # Steam
        "8621/udp"      # BitTorrent DHT
    )

    for service in "${services[@]}"; do
        sudo firewall-cmd --add-service="$service" --zone=FedoraWorkstation --permanent
    done

    for port in "${ports[@]}"; do
        sudo firewall-cmd --add-port="$port" --zone=FedoraWorkstation --permanent
    done

    sudo firewall-cmd --reload

    sudo semanage permissive -a firewalld_t

    sudo mkdir -p '/etc/systemd/resolved.conf.d'
    echo -e "DNS=94.140.14.14\nDNS=94.140.15.15\nDNS=1.1.1.1\nDNS=1.0.0.1\nDNS=8.8.8.8\nDNS=8.8.4.4" \
        | sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf

    sudo systemctl restart systemd-resolved

    sudo npm install -g hblock
    hblock

    echo "Configuración de seguridad completada en Fedora 41."
}

# Ejecutar las funciones
#configure-dnf
#configure-dnf-automatic
#change-hostname
#configure-repositories
#configure-flatpak-repositories
#install-essential-packages
#configure-zswap
#security-fedora
set-btrfs

sudo fwupdmgr refresh --force -y
sudo fwupdmgr get-updates -y
sudo fwupdmgr update -y
sudo dnf group upgrade core -y --exclude=zram*
sudo reboot