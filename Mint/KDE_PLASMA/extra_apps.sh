#!/bin/bash
declare -a apps
declare -a install
apps=(brave onlyoffice filezilla WhatsApp ytmdesktop KODI QEMU Balena-etcher Playonlinux Extra-Fonts)
s=${#apps[*]}
a=0
j=0

install_brave()
{
clear
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt install -y brave-browser
}

install_onlyoffice()
{
clear
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
chmod 644 /tmp/onlyoffice.gpg
sudo chown root:root /tmp/onlyoffice.gpg
sudo mv /tmp/onlyoffice.gpg /etc/apt/trusted.gpg.d/
echo 'deb https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee -a /etc/apt/sources.list.d/onlyoffice.list
sudo apt-get install onlyoffice-desktopeditors -y
}

install_filezilla()
{
clear
sudo apt install filezilla -y
}

install_ytmdesktop()
{
clear
flatpak install flathub app.ytmdesktop.ytmdesktop -y
}

install_KODI()
{
clear
flatpak install flathub tv.kodi.Kodi -y
}


install_WhatsApp()
{
clear
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y
}

install_QEMU()
{
clear
sudo apt install -y \
qemu qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools guestfs-tools virt-manager
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
}

install_Balena-etcher()
{
curl -1sLf \
   'https://dl.cloudsmith.io/public/balena/etcher/setup.deb.sh' \
   | sudo -E bash
sudo apt update
sudo apt -y install balena-etcher-electron
}

install_Playonlinux()
{
clear
flatpak install flathub org.phoenicis.playonlinux -y
flatpak install flathub com.usebottles.bottles -y
}

install_Extra_Fonts()
{
clear
sudo apt install -y ttf-mscorefonts-installer fonts-dejavu fonts-freefont-ttf ttf-bitstream-vera fonts-freefont-otf fonts-lyx xfonts-100dpi xfonts-75dpi fonts-roboto-hinted fonts-roboto-unhinted | tee 2> install.log
}

for i in "${apps[@]}"
do
    while [ $a -lt 1  ] && [ $j -lt ${#apps[*]} ]
    do
        read -p "Do you wish to install ${apps[$j]}? " yn
        case $yn in
            [Yy]* ) a=1;install[$j]=true;clear;;
            [Nn]* ) a=1;install[$j]=false;clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    j=$(( j+1 ))
a=0
done

j=0

for i in "${install[@]}"
do
    j=$(( j+1 ))
    if ($i -eq true)
    then
        case ${apps[$j]} in
            brave ) install_brave;;
            onlyoffice ) install_brave;;
            filezilla ) install_filezilla;;
            WhatsApp ) install_WhatsApp;;
            ytmdesktop ) install_ytmdesktop;;
            KODI ) install_KODI;;
            QEMU ) install_QEMU;;
            Balena-etcher ) install_QEMU;;
            Playonlinux ) install_Playonlinux;;
            Extra-Fonts) install_Extra_Fonts;;
        esac
    fi
done
