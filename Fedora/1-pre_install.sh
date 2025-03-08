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

# Función para mostrar mensajes con formato
function show_message {
    message="========
$1
========"
    echo "$message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> log.txt
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
    sudo dnf install -y --skip-broken --skip-unavailable @development-tools git
    sudo dnf install -y --skip-broken --skip-unavailable \
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

# Función para configurar ZRAM
function configure-zram {
    sudo dnf install -y zram*
    total_ram=$(free -b | awk '/^Mem:/{print $2}')

    zram0_size=$((total_ram * 20 / 100))
    if [ $zram0_size -gt $((4 * 1024 * 1024 * 1024)) ]; then
        zram0_size=$((4 * 1024 * 1024 * 1024))
    fi

    zram1_size=$((total_ram * 10 / 100))
    if [ $zram1_size -gt $((2 * 1024 * 1024 * 1024)) ]; then
        zram1_size=$((2 * 1024 * 1024 * 1024))
    fi

    echo "lz4" | sudo tee /sys/block/zram0/comp_algorithm
    echo $zram0_size | sudo tee /sys/block/zram0/disksize
    sudo swapon -p 70 /dev/zram0

    echo "zstd" | sudo tee /sys/block/zram1/comp_algorithm
    echo $zram1_size | sudo tee /sys/block/zram1/disksize
    sudo swapon -p 80 /dev/zram1

    sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon -p 90 /swapfile

    echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab

    grub="GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TIMEOUT=15
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

# Función para configurar ZSWAP
function configure-zswap {
    sudo dnf remove -y zram-generator*
    check_error "Failed to remove zram-generator* package."

    sudo dnf update -y
    check_error "Failed to update kernel modules."

    sudo modprobe lz4hc lz4hc_compress
    check_error "Failed to enable support for lz4hc."

    sudo touch /etc/dracut.conf.d/lz4hc.conf
    check_error "Failed to create dracut configuration file."

    echo "add_drivers+=\"lz4hc lz4hc_compress\"" | sudo tee -a /etc/dracut.conf.d/lz4hc.conf
    check_error "Failed to add lz4hc to dracut configuration."

    sudo dracut --regenerate-all --force
    check_error "Failed to regenerate initramfs files."

    echo "lz4hc" | sudo tee /sys/module/zswap/parameters/compressor
    check_error "Failed to set zswap compressor to lz4hc."

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

    sysctl_conf="/etc/sysctl.d/99-sysctl.conf"

    if [ -f "$sysctl_conf" ]; then
        sudo echo -n > "$sysctl_conf"
    else
        sudo touch "$sysctl_conf"
    fi

    grub="GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TIMEOUT=15
GRUB_DISTRIBUTOR=\"\$(sed 's, release .*\$,,' /etc/system-release)\"
GRUB_CMDLINE_LINUX_DEFAULT=\"quiet zswap.enabled=1 zswap.max_pool_percent=$zswap_max_pool zswap.zpool=z3fold zswap.compressor=lz4hc\"
GRUB_CMDLINE_LINUX=\"\"
GRUB_ENABLE_BLSCFG=true"

    grub_file="/etc/default/grub"
    sudo cp "$grub_file" "$grub_file.bak"
    echo "$grub" | sudo tee "$grub_file" > /dev/null

    echo "vm.swappiness=$swappiness" | sudo tee -a "$sysctl_conf"
    echo "vm.vfs_cache_pressure=$vfs_cache_pressure" | sudo tee -a "$sysctl_conf"

    sudo sysctl -p
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    script_file="/usr/local/bin/zswap"
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
} || echo zswap disabled'

    echo "$script_content" | sudo tee "$script_file" > /dev/null
    sudo chmod +x "$script_file"

    echo "#####zswap information#######"
    show_message "ZSWAP Settings"
    cat /sys/module/zswap/parameters/*
    show_message "ZSWAP Statistics"
    cat /sys/kernel/debug/zswap/*
    echo "#############################"

    sudo bash "$script_file"
    echo "ZSWAP configuration completed successfully."
    echo "Remember to restart your system to apply the changes."
}

# Función para configurar BTRFS
function set-btrfs {
    if [[ $(df -T / | awk 'NR==2 {print $2}') == "btrfs" ]]; then
        echo "Configuración de BTRFS en curso..."
        sudo cp /etc/fstab /etc/fstab_old

        ROOT_UUID=$(grep -E '/\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')
        HOME_UUID=$(grep -E '/home\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

        sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} /               btrfs   rw,noatime,space_cache=v2,compress=lzo,subvol=@ 0       1|" "/etc/fstab"
        sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home           btrfs   rw,noatime,space_cache=v2,compress=lzo,subvol=@home 0       2|" "/etc/fstab"

        clear
        cat /etc/fstab

        sudo btrfs filesystem defragment / -r -clzo
        root_partition=$(df -h / | awk 'NR==2 {print $1}')
        echo "La raíz está montada en la partición: $root_partition"

        sudo mkdir -p /mnt
        sudo mount $root_partition /mnt

        sudo btrfs subvolume create /mnt/@log
        sudo btrfs subvolume create /mnt/@cache
        sudo btrfs subvolume create /mnt/@tmp

        sudo mv /var/cache/* /mnt/@cache/
        sudo mv /var/log/* /mnt/@log/

        sudo btrfs balance start -m --force /mnt
        sudo btrfs balance start -d -s --force /mnt

        fstab="/etc/fstab"
        if [ -e "$fstab" ]; then
            {
                echo "# Añadiendo nuevos subvolúmenes"
                echo "UUID=$ROOT_UUID /var/log btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@log 0 2"
                echo "UUID=$ROOT_UUID /var/cache btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@cache 0 2"
                echo "UUID=$ROOT_UUID /var/tmp btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@tmp 0 2"
            } | sudo tee -a "$fstab" > /dev/null
        else
            echo "El archivo $fstab no existe. Verifica la ruta del archivo."
        fi

        sudo umount /mnt --force

        sudo chmod 1777 /var/tmp/
        sudo chmod 1777 /var/cache/
        sudo chmod 1777 /var/log/

        sudo dnf install -y timeshift inotify-tools

        sudo git clone https://github.com/Antynea/grub-btrfs.git /git/grub-btrfs/
        (
            cd /git/grub-btrfs
            sudo sed -i '/#GRUB_BTRFS_SNAPSHOT_KERNEL/a GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="systemd.volatile=state"' config
            sudo sed -i '/#GRUB_BTRFS_GRUB_DIRNAME/a GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' config
            sudo sed -i '/#GRUB_BTRFS_MKCONFIG=/a GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig' config
            sudo sed -i '/#GRUB_BTRFS_SCRIPT_CHECK=/a GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' config
            sudo make install
        )

        SERVICE_FILE="/lib/systemd/system/grub-btrfsd.service"
        sudo sed -i 's|^ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' "$SERVICE_FILE"

        sudo systemctl daemon-reload

        sudo mv /usr/bin/timeshift-gtk /usr/bin/timeshift-gtk-back
        echo -e '#!/bin/bash\n/bin/pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY /usr/bin/timeshift-gtk-back' | sudo tee /usr/bin/timeshift-gtk > /dev/null
        sudo chmod +x /usr/bin/timeshift-gtk

        sudo timeshift --create --comments "Initial Btrfs Snapshot"

        sudo systemctl stop timeshift && sudo systemctl disable timeshift

        sudo chmod +s /usr/bin/grub-btrfsd

        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
        sudo systemctl enable --now grub-btrfsd.service

        echo "Configuración BTRFS completa."
    else
        echo "La partición root no está montada en un volumen BTRFS."
    fi
}

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
sudo dnf group upgrade core -y --exclude=zram*
sudo reboot