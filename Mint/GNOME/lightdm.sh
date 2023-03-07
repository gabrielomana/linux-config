#!/bin/bash


#https://github.com/naueramant/lightdm-webkit-sequoia

sudo apt install lightdm
sudo systemctl disable gdm
sudo systemctl disable sddm

echo -e "[Seat:*]
#type=local
#pam-service=lightdm
#pam-autologin-service=lightdm-autologin
#pam-greeter-service=lightdm-greeter
#xserver-command=X
#xmir-command=Xmir
#xserver-config=
#xserver-layout=
#xserver-allow-tcp=false
#xserver-share=true
#xserver-hostname=
#xserver-display-number=
#xdmcp-manager=
#xdmcp-port=177
#xdmcp-key=
greeter-session=lightdm-webkit2-greeter
#greeter-hide-users=false
#greeter-allow-guest=true
#greeter-show-manual-login=false
#greeter-show-remote-login=true
user-session=GNOME
#allow-user-switching=true
#allow-guest=true
#guest-session=" | sudo tee /etc/lightdm/lightdm2.conf

sudo cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm_old.conf
sudo rm /etc/lightdm/lightdm.conf -rf
sudo mv /etc/lightdm/lightdm2.conf /etc/lightdm/lightdm.conf


