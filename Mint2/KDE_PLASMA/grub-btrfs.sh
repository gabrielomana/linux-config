#!/bin/bash

# Adjust compression in /etc/fstab
sed -i 's|defaults,noatime,space_cache=v2|defaults,noatime,space_cache=v2,compress=zstd:3|g' /etc/fstab

# Defragment and compress existing data
sudo btrfs fi defragment / -r -czstd

# Create additional subvolumes
btrfs subvolume create /@log
btrfs subvolume create /@cache
btrfs subvolume create /@tmp

# Move contents to new subvolumes
mv /@/var/cache/* /@cache/
mv /@/var/log/* /@log/

# Adjust fstab for new subvolumes
# Limpiar pantalla
clear
# Mostrar el estado actual de /etc/fstab
echo "Estado actual de /etc/fstab:"
cat /etc/fstab
# Solicitar UUID para /var/log
read -p "Ingresa el UUID para /var/log: " log
# Solicitar UUID para /var/cache
read -p "Ingresa el UUID para /var/cache: " cache
# Solicitar UUID para /var/tmp
read -p "Ingresa el UUID para /var/tmp: " tmp
# Ajustar compression en /etc/fstab
echo "UUID=$log /var/log btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@log 0 2" >> /@/etc/fstab
echo "UUID=$cache /var/cache btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@cache 0 2" >> /@/etc/fstab
echo "UUID=$tmp /var/tmp btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@tmp 0 2" >> /@/etc/fstab

# Install Timeshift
sudo apt install timeshift

# Install grub-btrfs from sources
sudo apt install build-essential git
mkdir -p ~/git
cd ~/git
git clone https://github.com/Antynea/grub-btrfs.git
cd grub-btrfs
sudo make install

# Configure grub-btrfs to monitor Timeshift snapshots
sudo update-grub
sudo apt install inotify-tools
sudo systemctl edit --full grub-btrfsd
# Change ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots to ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto

# Start grub-btrfsd and enable at boot
sudo systemctl start grub-btrfsd
sudo systemctl enable grub-btrfsd
