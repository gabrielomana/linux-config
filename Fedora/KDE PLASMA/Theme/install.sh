#!/bin/bash
#KVANTUM
sudo dnf -y copr enable gagbo/Kvantum
sudo dnf -y makecache --refresh
sudo dnf -y install kvantum
sudo dnf -y install latte-dock
sudo dnf -y install conky
clear
git clone https://github.com/vinceliuice/Orchis-kde.git
git clone https://github.com/vinceliuice/Orchis-theme.git
git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
git clone https://github.com/wsdfhjxc/virtual-desktop-bar.git
clear
echo -e "Install and configure plasmoids widget plasmoids widget requirements:\n- Plasma ConfigSaver\n- Latte Spacer\n- Latte Separator\n- Event Calendar\n- ditto menu\n\n"
read -p "Press any key to continue...." k
echo -e "Import Kwin Scripts from the folder:\n - forceblur-0.5.kwinscript\n - forceblur-0.6.kwinscript from the folder\n\n"
read -p "Press any key to continue...." k
cd Orchis-kde/
./install.sh
cd ..
cd Orchis-theme/
./install.sh
cd ..
cd Tela-circle-icon-theme/
./install.sh -a
cd ..
cd virtual-desktop-bar/
./scripts/install-dependencies-fedora.sh
./scripts/install-applet.sh
echo -e "Set Fonts Roboto\n\n"
read -p "Press any key to continue...." k
echo -e "Kvantum: Cagnge Theme Orchis\n\n"
kvantummanager
echo -e "Open Late Dock and import settings\n\n"
read -p "Press any key to continue...." k
cp conky ~/.conky/
echo -e "Add start_conky.sh (from conky folder) ti autostart\n\n"
read -p "Press any key to continue...." k
