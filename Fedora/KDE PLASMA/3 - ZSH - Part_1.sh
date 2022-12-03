#!/bin/bash

# ZSH & POWERLEVEL
sudo dnf -y install zsh -y
sudo chsh -s $(which zsh)
sudo chsh -s /usr/bin/zsh $USER
chsh -s $(which zsh)
chsh -s /usr/bin/zsh $USER
sudo mkdir ~/.fonts
sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -P /usr/share/fonts/
sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -P /usr/share/fonts/
sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -P /usr/share/fonts/
sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -P /usr/share/fonts/
fc-cache -f -v
reboot