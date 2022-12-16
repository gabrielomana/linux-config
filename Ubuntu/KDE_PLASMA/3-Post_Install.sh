#!/bin/bash
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.zshrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.zshrc

#sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/ohmyzsh/ohmyzsh/ /tmp/ohmyzsh/
ZSH= sh /tmp/ohmyzsh/tools/install.sh
rm -rf /tmp/ohmyzsh/
source ~/.zshrc 
