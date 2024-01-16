#!/bin/bash

############################################
# UPDATE SYSTEM DATE AND TIME
############################################

# Save the current directory in a variable
dir="$(pwd)"

# Update the system date and time using Google's response
date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"

############################################
# LANGUAGE AND LOCALES SETUP
############################################

# Install and configure language and locales
sudo apt install locales locales-all language-pack-es hunspell-es -y
sudo locale-gen "es_ES.UTF-8"
sudo localectl set-x11-keymap es.es
sudo update-locale LANG=es_ES.UTF-8
source /etc/default/locale

############################################
# SYSTEM UPDATE
############################################

# Update the system
sudo apt update
sudo apt full-upgrade -y
sudo dpkg --configure -a
sudo apt install -f
sudo apt clean
sudo apt --fix-broken install
sudo aptitude safe-upgrade -y
sudo apt install linux-headers-$(uname -r) -y

############################################
# NALA INSTALLATION AND UPDATE
############################################

# Install NALA if not installed
if ! command -v nala &> /dev/null; then
    echo "NALA not found. Installing NALA..."
    sudo apt install nala -y
fi

# Update NALA if installed
if command -v nala &> /dev/null; then
    echo "Updating NALA..."
    sudo nala fetch --auto --fetches 5 -y
    sudo nala update
    sudo nala upgrade -y
    sudo nala install -f
else
    echo "NALA not installed. Skipping update."
fi

############################################
# BASIC PACKAGES INSTALLATION
############################################
 clear
 echo "BASIC PACKAGES"
 sleep 3
 dir="$(pwd)"
 sudo nala install  -y apt-transport-https \
  apt-xapian-index \
  aptitude \
  bash-completion \
  bleachbit \
  build-essential \
  ca-certificates \
  coreutils \
  cmake \
  curl \
  debian-reference-es \
  devscripts \
  dialog \
  dirnagr \
  dkms \
  dos2unix \
  dpgv \
  gpgv \
  gnupg \
  linux-base \
  lsb-release \
  lzo \
  lz4 \
  make \
  man-db \
  manpages \
  memtest86+ \
  net-tools \
  netselect-apt \
  neofetch \
  p7zip \
  pipx \
  python3-pip \
  python3-venv \
  rsync \
  screen \
  software-properties-common \
  sudo \
  systemd-sysv \
  tree \
  unrar-free \
  util-linux \
  usbutils \
  wget \
  zip
 sleep 5
 clear

############################################
# ZSWAP, SWAPPINESS, AND GRUB UPDATE
############################################

# Configure Zswap, swappiness, and update Grub
echo "vm.swappiness=25" | sudo tee -a /etc/sysctl.conf
sudo cp /etc/default/grub /etc/default/grub_old
sudo cp "${dir}/dotfiles/grub" /etc/default/grub
sudo update-grub
echo "lz4" | sudo tee -a /etc/initramfs-tools/modules
echo "lz4_compress" | sudo tee -a /etc/initramfs-tools/modules
echo "z3fold" | sudo tee -a /etc/initramfs-tools/modules
sudo update-initramfs -u

############################################
# OPTIONAL SWITCH TO THE ROLLING BRANCH
############################################

a=0
f=0
while [ $a -lt 1 ]; do
    read -p "Do you want to switch to the Rolling branch (Y/N)? " yn
    case $yn in
        [Yy]* )
            a=1
            f=1
            ;;
        [Nn]* )
            a=1
            echo "OK"
            ;;
        * )
            echo "Please answer yes or no."
            ;;
    esac
done

if [ $f == 1 ]; then
    DEPS="bash coreutils dialog grep iputils-ping sparky-info sudo"

    PINGTEST0=$(sudo ping -c 1 debian.org | grep [0-9])
    if [ "$PINGTEST0" = "" ]; then
        echo "Debian server is offline... exiting..."
        exit 1
    fi

    PINGTEST1=$(sudo ping -c 1 sparkylinux.org | grep [0-9])
    if [ "$PINGTEST1" = "" ]; then
        echo "Sparky server is offline... exiting..."
        exit 1
    fi

    OSCODE=$(sudo cat /etc/lsb-release | grep Orion)
    if [ "$OSCODE" = "" ]; then
        echo "This is not Sparky 7 Orion Belt... exiting..."
        exit 1
    fi

    # Resto del código para cambiar a la rama "Rolling"
    clear
    echo "Cambiando a la rama Rolling..."
    sleep 3

    sudo nala install -y $DEPS

    # Verifica la conectividad a los servidores
    PINGTEST0=$(sudo ping -c 1 debian.org | grep [0-9])
    if [ "$PINGTEST0" = "" ]; then
        echo "Debian server is offline... exiting..."
        exit 1
    fi

    PINGTEST1=$(sudo ping -c 1 sparkylinux.org | grep [0-9])
    if [ "$PINGTEST1" = "" ]; then
        echo "Sparky server is offline... exiting..."
        exit 1
    fi

    # Verifica que estás en Sparky 7 Orion Belt
    OSCODE=$(sudo cat /etc/lsb-release | grep Orion)
    if [ "$OSCODE" = "" ]; then
        echo "This is not Sparky 7 Orion Belt... exiting..."
        exit 1
    fi

    # Actualiza el archivo sources.list para cambiar a la rama "Rolling"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak  # Respaldamos el archivo original

    sudo rm /etc/apt/sources.list
    echo -e "deb https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
    deb-src https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
    deb https://security.debian.org/debian-security testing-security main contrib non-free non-free-firmware
    deb-src https://security.debian.org/debian-security testing-security main contrib non-free non-free-firmware
    deb https://deb.debian.org/debian/ unstable main contrib non-free non-free-firmware
    deb-src https://deb.debian.org/debian/ unstable main contrib non-free non-free-firmware
    deb https://deb-multimedia.org/ testing main non-free" | sudo tee /etc/apt/sources.list

    sudo rm -f /etc/apt/sources.list.d/sparky.list
    echo -e "deb https://repo.sparkylinux.org/ core main
    deb-src https://repo.sparkylinux.org/ core main
    deb https://repo.sparkylinux.org/ sisters main
    deb-src https://repo.sparkylinux.org/ sisters main" | sudo tee /etc/apt/sources.list.d/sparky.list
    sudo apt update
    sudo mv /etc/apt/trusted.gpg "/etc/apt/trusted.gpg.d/sparky.gpg"
    sudo ln -s "/etc/apt/sparky.gpg" "/etc/apt/trusted.gpg.d/sparky.gpg"

    # Función para buscar y reemplazar en el archivo nala.list
    file_path="/etc/apt/sources.list.d/nala-sources.list"
    codename=$(curl -sL https://deb.debian.org/debian/dists/testing/InRelease | grep "^Codename:" | cut -d' ' -f2)
    if [ -f "$file_path" ]; then
        # Usa grep para verificar si la expresión ya existe en el archivo
        if grep -q "$codename" "$file_path"; then
            sudo sed -i "s/$codename/testing/g" "$file_path"
        else
            echo "La expresión no existe en el archivo $file_path."
        fi
    else
        echo "El archivo $file_path no existe."
    fi

    sudo curl -o /etc/apt/apt.conf.d/00default-release https://gist.githubusercontent.com/khimaros/21db936fa7885360f7bfe7f116b78daf/raw/698266fc043d6e906189b14e3428187ff0e7e7c8/00default-release

    # preferences_file="/etc/apt/preferences.d/99-lts-kernel"
    # if [ ! -e "$preferences_file" ]; then
    #     echo "Package: linux-image-amd64-lts-*
    #     Pin: release *
    #     Pin-Priority: 1001" | sudo tee "$preferences_file" > /dev/null
    # fi

    sudo nala update
    sudo nala upgrade -y
    sudo apt full-upgrade -y
    sudo apt dist-upgrade -y
    sudo dpkg --configure -a
    sudo apt install -f
    sudo apt autoremove -y
    sudo aptitude safe-upgrade -y

    # SECURITY UPGRADES FRON UNSTABLE
    clear
    sudo nala install -y debsecan
    sudo curl -o /usr/sbin/debsecan-apt-priority https://gist.githubusercontent.com/khimaros/21db936fa7885360f7bfe7f116b78daf/raw/698266fc043d6e906189b14e3428187ff0e7e7c8/debsecan-apt-priority
    sudo curl -o /etc/apt/apt.conf.d/99debsecan https://gist.githubusercontent.com/khimaros/21db936fa7885360f7bfe7f116b78daf/raw/698266fc043d6e906189b14e3428187ff0e7e7c8/99debsecan
    sudo curl -o /etc/apt/preferences.d/unstable-packages https://gist.githubusercontent.com/khimaros/21db936fa7885360f7bfe7f116b78daf/raw/698266fc043d6e906189b14e3428187ff0e7e7c8/unstable-packages
    sudo chmod 755 /usr/sbin/debsecan-apt-priority
    sudo ln -sf /var/lib/debsecan/apt_preferences /etc/apt/preferences.d/unstable-security-packages
    sudo apt update
    sudo apt upgrade -y
else
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak  # Respaldamos el archivo original

    echo -e "deb https://ftp.debian.org/debian/ stable contrib main non-free non-free-firmware
    deb-src https://ftp.debian.org/debian/ stable contrib main non-free non-free-firmware
    deb https://ftp.debian.org/debian/ stable-updates contrib main non-free non-free-firmware
    deb-src https://ftp.debian.org/debian/ stable-updates contrib main non-free non-free-firmware
    deb https://ftp.debian.org/debian/ stable-proposed-updates contrib main non-free non-free-firmware
    deb-src https://ftp.debian.org/debian/ stable-proposed-updates contrib main non-free non-free-firmware
    deb https://ftp.debian.org/debian/ stable-backports contrib main non-free non-free-firmware
    deb-src https://ftp.debian.org/debian/ stable-backports contrib main non-free non-free-firmware
    deb https://security.debian.org/debian-security/ stable-security contrib main non-free non-free-firmware
    deb-src https://security.debian.org/debian-security/ stable-security contrib main non-free non-free-firmware
    deb https://www.deb-multimedia.org stable main non-free
    deb https://www.deb-multimedia.org stable-backports main" | sudo tee /etc/apt/sources.list

    sudo nala update
    sudo nala upgrade -y
    sudo apt full-upgrade -y
    sudo apt dist-upgrade -y
    sudo dpkg --configure -a
    sudo apt install -f
    sudo apt autoremove -y
    sudo aptitude safe-upgrade -y
fi


############################################
# PIPEWIRE AND WIREPLUMBER INSTALLATION
############################################

# Get the codename of the latest LTS version of Ubuntu
ubuntu_lts=$(curl -s https://changelogs.ubuntu.com/meta-release-lts | grep Dist: | tail -n1 | awk -F '[: ]+' '{print $NF}' | tr '[:upper:]' '[:lower:]')

# Create the pipewire-upstream.list file
echo "deb http://ppa.launchpad.net/pipewire-debian/pipewire-upstream/ubuntu $ubuntu_lts main" | sudo tee /etc/apt/sources.list.d/pipewire-upstream.list > /dev/null

# Create the wireplumber-upstream.list file
echo "deb http://ppa.launchpad.net/pipewire-debian/wireplumber-upstream/ubuntu $ubuntu_lts main" | sudo tee /etc/apt/sources.list.d/wireplumber-upstream.list > /dev/null

# Install the key
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 25088A0359807596

# Update the system
sudo apt update
sudo apt upgrade -y
sudo apt full-upgrade -y

# Install necessary packages
sudo apt install -y \
    libfdk-aac2 \
    libldacbt-{abr,enc}2 \
    libopenaptx0 \
    gstreamer1.0-pipewire \
    libpipewire-0.3-{0,dev,modules} \
    libspa-0.2-{bluetooth,dev,jack,modules} \
    pipewire{,-{audio-client-libraries,pulse,bin,locales,tests}} \
    pipewire-doc \
    libpipewire-module-x11-bell \
    wireplumber{,-doc} \
    gir1.2-wp-0.4 \
    libwireplumber-0.4-{0,dev} \
    wireplumber-locales

# Disable PulseAudio
systemctl --user --now disable pulseaudio.{socket,service}
systemctl --user mask pulseaudio

# Enable Pipewire
sudo apt reinstall pipewire pipewire-bin pipewire-pulse -y
systemctl --user --now enable pipewire pipewire-pulse
systemctl --user --now enable pipewire{,-pulse}.{socket,service}
systemctl --user --now enable wireplumber.service


############################################
# GRUB-BTRFS AND TIMESHIFT CONFIGURATION
############################################

# Check if the root partition is on Btrfs
if [[ $(df -T / | awk 'NR==2 {print $2}') == "btrfs" ]]; then
    # Get the UUID of the root partition
    ROOT_UUID=$(grep -E '/\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

    # Get the UUID of the home partition
    HOME_UUID=$(grep -E '/home\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

    # Modify the /etc/fstab file for the root partition
    sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} / btrfs btrfsrw,noatime,compress=lzo,space_cache=v2,subvol=@ 0 0|" "/etc/fstab"
    # Modify the /etc/fstab file for the home partition
    sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home  btrfs btrfsrw,noatime,compress=lzo,space_cache=v2,subvol=@home 0 0|" "/etc/fstab"
    
    # Clear the screen
    clear
    cat /etc/fstab
    sudo cp /etc/fstab /etc/fstab_old

    # Defragment the Btrfs file system
    sudo btrfs filesystem defragment / -r -clzo

    # Mount the Btrfs device
    root_partition=$(df -h / | awk 'NR==2 {print $1}')
    echo "Root is mounted on partition: $root_partition"

    # Create the /mnt directory if it doesn't exist
    sudo mkdir -p /mnt

    # Mount the root partition to /mnt
    sudo mount $root_partition /mnt

    # Create additional subvolumes
    sudo btrfs subvolume create /mnt/@log
    sudo btrfs subvolume create /mnt/@cache
    sudo btrfs subvolume create /mnt/@tmp

    # Move existing contents of /var/cache and /var/log to the new subvolumes
    sudo mv /var/cache/* /mnt/@cache/
    sudo mv /var/log/* /mnt/@log/

    # Balance to duplicate metadata and system
    sudo btrfs balance start -m /mnt

    # Balance to set data and global reserve as non-duplicated
    sudo btrfs balance start -d -s /mnt

    # Check if the fstab file exists
    fstab="/etc/fstab"
    if [ -e "$fstab" ]; then
        # Adjust compression in /etc/fstab with the new subvolumes
        {
            echo "# Adding New Subvolumes"
            echo "UUID=$ROOT_UUID /var/log btrfs btrfsrw,noatime,compress=lzo,space_cache=v2,subvol=@log 0 0"
            echo "UUID=$ROOT_UUID /var/cache btrfs btrfsrw,noatime,compress=lzo,space_cache=v2,subvol=@cache 0 0"
            echo "UUID=$ROOT_UUID /var/tmp btrfs btrfsrw,noatime,compress=lzo,space_cache=v2,subvol=@tmp 0 0"
        } | sudo tee -a "$fstab" > /dev/null
    else
        echo "The file $fstab does not exist. Verify the file path."
    fi

    # Unmount the Btrfs device
    sudo umount /mnt

    # Set permissions for /var/tmp, /var/cache, and /var/log
    sudo chmod 1777 /var/tmp/
    sudo chmod 1777 /var/cache/
    sudo chmod 1777 /var/log/

    # Install Timeshift
    sudo apt install timeshift build-essential git -y

    # Clone the grub-btrfs repository and compile and install
    sudo git clone https://github.com/Antynea/grub-btrfs.git /git/grub-btrfs/
    (
        cd /git/grub-btrfs || exit
        sudo make install
    )

    # Install inotify-tools
    sudo apt install inotify-tools -y

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
    sudo systemctl restart grub-btrfsd
    sudo systemctl start grub-btrfsd
    sudo systemctl enable grub-btrfsd

    # Update grub
    sudo update-grub

else
    echo "The root partition is not mounted on a BTRFS volume."
fi

############################################
# CLEANING AND FINAL SYSTEM UPDATE
############################################

# Clean and final system update
sudo apt install -y bleachbit
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sudo apt update
sudo apt --fix-broken install
sudo aptitude safe-upgrade -y

# Reboot the system
sudo reboot
