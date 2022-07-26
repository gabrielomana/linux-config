#!/bin/bash
sudo cp /etc/profile.d/vte*.sh /etc/profile.d/vte.sh
cp -r Files/TILIX/tilix ~/.config/
git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use
cp -r Files/.zshrc ~/
cp -r Files/.p10k.zsh ~/
cp -r Files/topgrade.toml ~/.config
source ~/.zshrc 
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.zshrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.zshrc
source ~/.zshrc
