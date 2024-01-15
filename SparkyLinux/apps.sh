#!/bin/bash

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