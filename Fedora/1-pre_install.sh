# Función para manejar errores
function check_error {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Función para mostrar mensajes con formato
function show_message {
    echo "========"
    echo "$1"
    echo "========"
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
    sudo dnf clean all
    sudo dnf update -y
    sudo dnf upgrade -y
    check_error "Failed to configure DNF."
    sleep 3
}

# Función para configurar DNF Automatic
function configure-dnf-automatic {
    # Instalar dnf-automatic y tracer
    sudo dnf install -y dnf-automatic dnf-plugins-extras-tracer

    # Editar el archivo /etc/dnf/automatic.conf para modificar los valores
    sudo sed -i '/^upgrade_type/ s/default/security/' /etc/dnf/automatic.conf
    sudo sed -i '/^apply_updates/ s/no/yes/' /etc/dnf/automatic.conf

    # Clonar el repositorio dnf-automatic-restart
    sudo git clone https://github.com/agross/dnf-automatic-restart.git /usr/local/src/dnf-automatic-restart
    sudo ln -s /usr/local/src/dnf-automatic-restart/dnf-automatic-restart /usr/local/sbin/dnf-automatic-restart
    # Habilitar dnf-automatic
    sudo systemctl enable dnf-automatic-install.timer
    # Crear un drop-in para ejecutar dnf-automatic-restart después de la instalación automática
    sudo mkdir -p /etc/systemd/system/dnf-automatic-install.service.d
    echo "[Service]" | sudo tee /etc/systemd/system/dnf-automatic-install.service.d/restart.conf > /dev/null
    echo "ExecStartPost=/usr/local/sbin/dnf-automatic-restart -d" | sudo tee -a /etc/systemd/system/dnf-automatic-install.service.d/restart.conf > /dev/null

    # Reiniciar el servicio dnf-automatic-install.timer después de editar el drop-in
    sudo systemctl daemon-reload
    # Imprimir mensaje informativo
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
    sudo dnf -y groupupdate core
}

# Función para instalar paquetes esenciales
function install-essential-packages {
    sudo dnf install @development-tools git -y
    sudo dnf -y install util-linux-user dnf-plugins-core openssl finger dos2unix nano sed sudo numlockx wget curl git nodejs cargo hunspell-es curl cmake gcc-c++ cabextract xorg-x11-font-utils fontconfig btrfs*
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

# Función para configurar ZRAM
function configure-zram {
    sudo dnf install -y zram*
    # Obtener la cantidad de RAM en el sistema
    total_ram=$(free -b | awk '/^Mem:/{print $2}')

    # Calcular el 20% de la RAM o 6 GB, lo que sea menor
    zram0_size=$((total_ram * 20 / 100))
    if [ $zram0_size -gt $((4 * 1024 * 1024 * 1024)) ]; then
        zram0_size=$((4 * 1024 * 1024 * 1024))
    fi

    zram1_size=$((total_ram * 10 / 100))
    if [ $zram1_size -gt $((2 * 1024 * 1024 * 1024)) ]; then
        zram1_size=$((2 * 1024 * 1024 * 1024))
    fi

    # Establecer la prioridad de zram
    zram0_priority=70
    zram1_priority=80

    # Configurar zram0 con lz4 como algoritmo de compresión
    echo "lz4" | sudo tee /sys/block/zram0/comp_algorithm
    echo $zram0_size | sudo tee /sys/block/zram0/disksize
    echo $zram0_priority | sudo tee /sys/block/zram0/priority

    # Configurar zram1 con zstd como algoritmo de compresión
    echo "zstd" | sudo tee /sys/block/zram1/comp_algorithm
    echo $zram1_size | sudo tee /sys/block/zram1/disksize
    echo $zram1_priority | sudo tee /sys/block/zram1/priority

    # Habilitar zram
    sudo modprobe zram
    sudo systemctl enable zram

    # Obtener la cantidad de RAM en el sistema
    total_ram=$(free -b | awk '/^Mem:/{print $2}')

    # Calcular el 20% de la RAM o 4 GB, lo que sea menor, para el dispositivo de 4 GB
    zram0_size=$((total_ram * 20 / 100))
    if [ $zram0_size -gt $((4 * 1024 * 1024 * 1024)) ]; then
        zram0_size=$((4 * 1024 * 1024 * 1024))
    fi

    # Calcular el 10% de la RAM o 2 GB, lo que sea menor, para el dispositivo de 2 GB
    zram1_size=$((total_ram * 10 / 100))
    if [ $zram1_size -gt $((2 * 1024 * 1024 * 1024)) ]; then
        zram1_size=$((2 * 1024 * 1024 * 1024))
    fi

    # Configurar el número de dispositivos ZRAM
    sudo modprobe zram num_devices=2

    # Configurar zram0 con lz4 como algoritmo de compresión
    echo "lz4" | sudo tee /sys/block/zram0/comp_algorithm
    echo $zram0_size | sudo tee /sys/block/zram0/disksize
    sudo swapon -p 70 /dev/zram0

    # Configurar zram1 con zstd como algoritmo de compresión y establecer streams
    echo "zstd" | sudo tee /sys/block/zram1/comp_algorithm
    echo $zram1_size | sudo tee /sys/block/zram1/disksize
    sudo zstd --train -B $zram1_size /dev/zram1
    sudo swapon -p 80 /dev/zram1

    # Crear un swapfile de 1 GB
    sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon -p 90 /swapfile

    # Añadir el swapfile al fstab para que se monte al arrancar
    echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab

    # Configuración de GRUB para ZRAM
    grub="GRUB_DEFAULT=saved
    GRUB_SAVEDEFAULT=saved
    GRUB_DISABLE_SUBMENU=true
    GRUB_TIMEOUT=15
    #GRUB_TIMEOUT_STYLE=hidden
    GRUB_DISTRIBUTOR=\"\$(sed 's, release .*\$,,' /etc/system-release)\"
    GRUB_CMDLINE_LINUX_DEFAULT=\"quiet zram.enabled=1 zram.zstd_max_comp_stream=6 zram.zstd_comp_level=3\"
    GRUB_CMDLINE_LINUX=\"\"
    GRUB_ENABLE_BLSCFG=true"

    grub_file="/etc/default/grub"
    sudo cp "$grub_file" "$grub_file.bak"
    echo "$grub" | sudo tee "$grub_file" > /dev/null

    show_message "ZRAM Configuration"
    cat /etc/default/grub
}


function configure-zswap {
    # Function to check for errors
    function check_error {
        if [ $? -ne 0 ]; then
            echo "Error: $1"
            exit 1
        fi
    }

    # Function to show messages with formatting
    function show_message {
        echo "========"
        echo "$1"
        echo "========"
    }

    # Enable ZSWAP
    sudo dnf remove -y zram-generator*
    check_error "Failed to remove zram-generator* package."
    sleep 3

    # Update kernel modules
    sudo dnf update -y
    check_error "Failed to update kernel modules."
    sleep 3

    # Enable support for lz4hc
    sudo modprobe lz4hc lz4hc_compress
    check_error "Failed to enable support for lz4hc."
    sleep 3

    # Create dracut configuration file
    sudo touch /etc/dracut.conf.d/lz4hc.conf
    check_error "Failed to create dracut configuration file."
    sleep 3

    # Add lz4hc to the list of modules in dracut configuration file
    echo "add_drivers+=\"lz4hc lz4hc_compress\"" | sudo tee -a /etc/dracut.conf.d/lz4hc.conf
    check_error "Failed to add lz4hc to dracut configuration."
    sleep 3

    # Regenerate initramfs files
    sudo dracut --regenerate-all --force
    check_error "Failed to regenerate initramfs files."
    sleep 3

    # Set zswap compressor to lz4hc
    echo "lz4hc" | sudo tee /sys/module/zswap/parameters/compressor
    check_error "Failed to set zswap compressor to lz4hc."
    sleep 3

    # Determine system parameters based on total RAM
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
        # ZSWAP Configuration
        swappiness=10
        zswap_max_pool=20
        vfs_cache_pressure=75

        # ZRAM Configuration
        #configure-zram
        #return 0
    fi

    sysctl_conf="/etc/sysctl.d/99-sysctl.conf"

    if [ -f "$sysctl_conf" ]; then
        # Clear the contents of the file
        sudo echo -n > "$sysctl_conf"
    else
        # Create the file if it doesn't exist
        sudo touch "$sysctl_conf"
    fi

    # GRUB configuration
    grub="GRUB_DEFAULT=saved
    GRUB_SAVEDEFAULT=saved
    GRUB_DISABLE_SUBMENU=true
    GRUB_TIMEOUT=15
    #GRUB_TIMEOUT_STYLE=hidden
    GRUB_DISTRIBUTOR=\"\$(sed 's, release .*\$,,' /etc/system-release)\"
    GRUB_CMDLINE_LINUX_DEFAULT=\"quiet zswap.enabled=1 zswap.max_pool_percent=$zswap_max_pool zswap.zpool=z3fold zswap.compressor=lz4hc\"
    GRUB_CMDLINE_LINUX=\"\"
    GRUB_ENABLE_BLSCFG=true"

    grub_file="/etc/default/grub"
    sudo cp "$grub_file" "$grub_file.bak"
    echo "$grub" | sudo tee "$grub_file" > /dev/null

    # Add swappiness and vfs_cache_pressure settings
    echo "vm.swappiness=$swappiness" | sudo tee -a "$sysctl_conf"
    echo "vm.vfs_cache_pressure=$vfs_cache_pressure" | sudo tee -a "$sysctl_conf"

    # Apply sysctl settings
    sudo sysctl -p

    # Update GRUB configuration
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    # Nombre del archivo
    script_file="/usr/local/bin/zswap"

    # Contenido del script
    script_content='#!/bin/bash
    MDL=/sys/module/zswap
    DBG=/sys/kernel/debug/zswap
    PAGE=$(( $(cat $DBG/stored_pages) * 4096 ))
    POOL=$(( $(cat $DBG/pool_total_size) ))
    Show(){
        printf "========\n$1\n========\n"
        grep -R . $2 2>&1 | sed "s|.*/||"
    }
    Show Settings $MDL
    Show Stats    $DBG
    printf "\nCompression ratio: "
    [ $POOL -gt 0 ] && {
        echo "scale=3; $PAGE / $POOL" | bc
    } || echo zswap disabled
    '

    # Crear el archivo
    echo "$script_content" | sudo tee "$script_file" > /dev/null

    # Asignar permisos
    sudo chmod +x "$script_file"

    # Display zswap information
    echo "#####zswap information#######"
    show_message "ZSWAP Settings"
    cat /sys/module/zswap/parameters/*
    show_message "ZSWAP Statistics"
    cat /sys/kernel/debug/zswap/*
    echo "#############################"

    # Display compression ratio using the provided zswap script
    sudo bash "$script_file"

    # Completion message
    echo "ZSWAP configuration completed successfully."
    echo "Remember to restart your system to apply the changes."
}


function set-btrfs {
    # Verificar si la partición root está en Btrfs
    if [[ $(df -T / | awk 'NR==2 {print $2}') == "btrfs" ]]; then
        sudo cp /etc/fstab /etc/fstab_old
        # Obtener el UUID de la partición raíz
        ROOT_UUID=$(grep -E '/\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')
        # Obtener el UUID de la partición home
        HOME_UUID=$(grep -E '/home\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')
        # Modificar el archivo /etc/fstab para la partición raíz
        sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} /               btrfs   rw,noatime,space_cache=v2,compress=lzo,subvol=@ 0       1|" "/etc/fstab"
        # Modificar el archivo /etc/fstab para la partición home
        sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home           btrfs   rw,noatime,space_cache=v2,compress=lzo,subvol=@home 0       2|" "/etc/fstab"
        # Limpiar la pantalla
        clear
        cat /etc/fstab
        # Desfragmentar el sistema de archivos Btrfs
        sudo btrfs filesystem defragment / -r -clzo
        # Montar el dispositivo Btrfs
        root_partition=$(df -h / | awk 'NR==2 {print $1}')
        echo "La raíz está montada en la partición: $root_partition"
        # Creamos el directorio /mnt si no existe
        sudo mkdir -p /mnt
        # Montamos la partición raíz en /mnt
        sudo mount $root_partition /mnt
        # Crear subvolúmenes adicionales
        sudo btrfs subvolume create /mnt/@log
        sudo btrfs subvolume create /mnt/@cache
        sudo btrfs subvolume create /mnt/@tmp
        # Mover los contenidos existentes de /var/cache y /var/log a los nuevos subvolúmenes
        sudo mv /var/cache/* /mnt/@cache/
        sudo mv /var/log/* /mnt/@log/
        # Balanceo para duplicar metadatos y sistema
        sudo btrfs balance start -m --force /mnt
        # Balanceo para configurar datos y reserva global como no duplicados
        sudo btrfs balance start -d -s --force /mnt
        # Verificar si el archivo fstab existe
        fstab="/etc/fstab"
        if [ -e "$fstab" ]; then
            # Ajustar compresión en /etc/fstab con los nuevos subvolúmenes
            {
                echo "# Adding New Subvolumes"
                echo "UUID=$ROOT_UUID /var/log btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@log 0 2"
                echo "UUID=$ROOT_UUID /var/cache btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@cache 0 2"
                echo "UUID=$ROOT_UUID /var/tmp btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@tmp 0 2"
            } | sudo tee -a "$fstab" > /dev/null
        else
            echo "El archivo $fstab no existe. Verifica la ruta del archivo."
        fi
        # Desmontar el dispositivo Btrfs
        sudo umount /mnt --force

        # Establecer permisos para /var/tmp, /var/cache y /var/log
        sudo chmod 1777 /var/tmp/
        sudo chmod 1777 /var/cache/
        sudo chmod 1777 /var/log/

        # Install Timeshift
    sudo dnf install -y timeshift inotify-tools

    # Clone the grub-btrfs repository and compile and install
    sudo git clone https://github.com/Antynea/grub-btrfs.git /git/grub-btrfs/
    (
        cd /git/grub-btrfs
        sudo sed -i '/#GRUB_BTRFS_SNAPSHOT_KERNEL/a GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="systemd.volatile=state"' config
        sudo sed -i '/#GRUB_BTRFS_GRUB_DIRNAME/a GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' config
        sudo sed -i '/#GRUB_BTRFS_MKCONFIG=/a GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig' config
        sudo sed -i '/#GRUB_BTRFS_SCRIPT_CHECK=/a GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' config
        sudo make install
    )

    # Modify the service file to add --timeshift-auto
    SERVICE_FILE="/lib/systemd/system/grub-btrfsd.service"
    sudo sed -i 's|^ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' "$SERVICE_FILE"

    # Reload systemd configuration
    sudo systemctl daemon-reload

    # Rename the timeshift-gtk file in /usr/bin/
    sudo mv /usr/bin/timeshift-gtk /usr/bin/timeshift-gtk-back

    # Create a new timeshift-gtk file with the given content
    echo -e '#!/bin/bash\n/bin/pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY /usr/bin/timeshift-gtk-back' | sudo tee /usr/bin/timeshift-gtk > /dev/null

    # Grant execute permissions to the new file
    sudo chmod +x /usr/bin/timeshift-gtk

    sudo timeshift --create --comments "initial"

    sudo systemctl stop timeshift && sudo systemctl disable timeshift
    sudo chmod +s /usr/bin/grub-btrfsd

    # Restart the service
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo systemctl enable --now grub-btrfsd.service

    else
        echo "La partición root no está montada en un volumen BTRFS."
    fi
}

function security-fedora {
  # Snapshot
  sudo timeshift --create --comments "pre-security"

  # Instalar resolvconf, firewalld y firewall-config
  sudo dnf install resolvconf firewalld firewall-config -y
  sudo systemctl enable firewalld

  # Configuración del firewall y SELinux
  sudo dnf install -y selinux-policy selinux-policy-targeted policycoreutils policycoreutils-python-utils setools
  sudo sed -i 's/SELINUX=.*/SELINUX=enforcing/g' /etc/selinux/config

  # Establecer la zona por defecto en FedoraWorkstation
  sudo firewall-cmd --set-default-zone=FedoraWorkstation

  # Limpia todas las reglas existentes
  sudo firewall-cmd --complete-reload
  sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1-65535/tcp --permanent
  sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1-65535/udp --permanent
  sudo firewall-cmd --reload
  sudo firewall-cmd --complete-reload

  # Permitir tráfico de loopback
  sudo firewall-cmd --add-interface=lo --zone=FedoraWorkstation --permanent

  # Permitir tráfico ya establecido y relacionado
  sudo firewall-cmd --zone=FedoraWorkstation --add-service=http --permanent

  # Permitir ping (ICMP)
  sudo firewall-cmd --add-icmp-block-inversion --zone=FedoraWorkstation --permanent
  sudo firewall-cmd --add-service=ping --zone=FedoraWorkstation --permanent

  # Permitir tráfico DNS (UDP)
  sudo firewall-cmd --add-service=dns --zone=FedoraWorkstation --permanent

  # Permitir traceroute (UDP)
  sudo firewall-cmd --add-port=33434-33523/udp --zone=FedoraWorkstation --permanent

  # Puertos y servicios específicos
  declare -a services=(
    "http"          # Puerto 80/tcp
    "https"         # Puerto 443/tcp
    "ssh"           # Puerto 22/tcp
    "samba"         # Puerto 137-138/udp, 139/tcp, 445/tcp
    "ftp"           # Puerto 21/tcp
    "sftp"          # Puerto 22/tcp
    "http"          # Puerto 80/tcp
    "dnsmasq"       # Puerto 5353/udp
    "dhcpv6-client" # Puerto 546/udp
    "pop3"          # Puerto 110/tcp (ejemplo: para correos)
    "pop3s"         # Puerto 995/tcp (ejemplo: para correos seguros)
    "imap"          # Puerto 143/tcp (ejemplo: para correos)
    "imaps"         # Puerto 993/tcp (ejemplo: para correos seguros)
    "kde-connect"   # Puertos 1714 y 1715 (ejemplo: para KDE Connect)
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
    "6881-6891/tcp" # Puertos típicos para BitTorrent
    "22/tcp"        # SSH
    "62062-62072/tcp" # Steam In-Home Streaming
    "8621/udp"      # BitTorrent DHT
  )

  # Agregar reglas para tráfico entrante y saliente
  for service in "${services[@]}"; do
    sudo firewall-cmd --add-service="$service" --zone=FedoraWorkstation --permanent
  done

  for port in "${ports[@]}"; do
    sudo firewall-cmd --add-port="$port" --zone=FedoraWorkstation --permanent
  done

  # Permitir traceroute (UDP) también para tráfico saliente
  sudo firewall-cmd --add-port=33434-33523/udp --zone=FedoraWorkstation --permanent

  # Permitir tráfico saliente del puerto de control FTP (puerto 21)
  sudo firewall-cmd --add-port=21/tcp --zone=FedoraWorkstation --permanent

  # Permitir tráfico de datos FTP (puertos pasivos, ajusta según tu configuración)
  sudo firewall-cmd --add-port=30000-31000/tcp --zone=FedoraWorkstation --permanent

  # Configuración de SELinux (configurado para modo enforcing)
  sudo semanage permissive -a firewalld_t

  # Configurar servidores DNS de AdGuard, Cloudflare y Google en resolved.conf.d
  sudo mkdir -p '/etc/systemd/resolved.conf.d'
  echo "DNS=94.140.14.14" | sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf
  echo "DNS=94.140.15.15" | sudo tee -a /etc/systemd/resolved.conf.d/99-dns-over-tls.conf
  echo "DNS=1.1.1.1" | sudo tee -a /etc/systemd/resolved.conf.d/99-dns-over-tls.conf
  echo "DNS=1.0.0.1" | sudo tee -a /etc/systemd/resolved.conf.d/99-dns-over-tls.conf
  echo "DNS=8.8.8.8" | sudo tee -a /etc/systemd/resolved.conf.d/99-dns-over-tls.conf
  echo "DNS=8.8.4.4" | sudo tee -a /etc/systemd/resolved.conf.d/99-dns-over-tls.conf

  # Recargar firewalld para aplicar los cambios
  sudo systemctl restart firewalld

  # Instalar y ejecutar hblock
  sudo npm install -g hblock
  hblock
}

configure-dnf
configure-dnf-automatic
change-hostname
configure-repositories
configure-flatpak-repositories
install-essential-packages
configure-zswap
security-fedora
set-btrfs

sudo fwupdmgr refresh --force -y
sudo fwupdmgr get-updates -y
sudo fwupdmgr update -y
sudo dnf group update core -y --exclude=zram*
sudo reboot