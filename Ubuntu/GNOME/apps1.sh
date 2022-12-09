!/bin/bash
clear
# REPOSITORIES
echo "REPOSITORIES"

####Vanilla
sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
sudo add-apt-repository ppa:mozillateam/ppa -y

sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo add-apt-repository ppa:appimagelauncher-team/stable -y
sudo add-apt-repository ppa:ubuntucinnamonremix/all -y
sudo apt-add-repository -y ppa:teejee2008/ppa -y


sudo add-apt-repository ppa:webupd8team/y-ppa-manager -y
echo -e "deb https://ppa.launchpadcontent.net/webupd8team/y-ppa-manager/ubuntu/ impish main\n# deb-src https://ppa.launchpadcontent.net/webupd8team/y-ppa-manager/ubuntu/ impish main" | sudo tee /etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-jammy.list
sudo wget --no-check-certificate -qO - https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=index&search=0x7B2C3B0889BF5709A105D03AC2518248EEA14886 | gpg --dearmor | sudo tee /usr/share/keyrings/webupd8team.gpg

sudo apt -y update && sudo apt -y upgrade