#!/bin/bash

############################################
# BASIC PACKAGES INSTALLATION
############################################
 clear
 echo "BASIC PACKAGES"
 sleep 3
 dir="$(pwd)"
LISTt="apt-transport-https \
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
  dirmngr \
  dkms \
  dos2unix \
  gpgv \
  gnupg \
  linux-base \
  lsb-release \
  liblzo* \
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
  zip"
 sudo apt-get --ignore-missing install $(echo $LIST | sed -e 's/wifite//')
 sleep 5
 clear