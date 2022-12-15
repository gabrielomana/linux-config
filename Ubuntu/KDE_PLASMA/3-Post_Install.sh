#!/bin/bash
#sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/ohmyzsh/ohmyzsh/ /tmp/ohmyzsh/
ZSH= sh /tmp/ohmyzsh/tools/install.sh
rm -rf /tmp/ohmyzsh/
source ~/.zshrc 
