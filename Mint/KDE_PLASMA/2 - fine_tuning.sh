#!/bin/bash
a=0
install=false

install_ZSH()
{
clear

########Install ZSH##########
if command -v zsh &> /dev/null && command -v git &> /dev/null && command -v wget &> /dev/null; then
    echo -e "ZSH and Git are already installed\n"
else
    if sudo apt install -y zsh git wget || sudo pacman -S zsh git wget || sudo dnf install -y zsh git wget || sudo yum install -y zsh git wget || sudo brew install git zsh wget || pkg install git zsh wget ; then
        echo -e "zsh wget and git Installed\n"
    else
        echo -e "Please install the following packages first, then try again: zsh git wget \n" && exit
    fi
fi


######## BackUp .zshrc ##########
if mv -n ~/.zshrc ~/.zshrc-backup-$(date +"%Y-%m-%d"); then # backup .zshrc
    echo -e "Backed up the current .zshrc to .zshrc-backup-date\n"
fi


######## Installing oh-my-zsh ##########

echo -e "Installing oh-my-zsh\n"
if [ -d ~/.oh-my-zsh ]; then
    echo -e "oh-my-zsh is already installed\n"
    git -C ~/.oh-my-zsh remote set-url origin https://github.com/ohmyzsh/ohmyzsh.git
else
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
fi

######## dotfiles ##########

cp -f Files/.zshrc ~/
mkdir -p ~/.cache/zsh/                # this will be used to store .zcompdump zsh completion cache files which normally clutter $HOME

if [ -f ~/.zcompdump ]; then
    mv ~/.zcompdump* ~/.cache/zsh/
fi

######## Plugins ##########

if [ -d ~/.oh-my-zsh/plugins/zsh-autosuggestions ]; then
    cd ~/.oh-my-zsh/plugins/zsh-autosuggestions && git pull
else
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
fi

if [ -d ~/.oh-my-zsh/plugins/fast-syntax-highlighting ]; then
    cd ~/.oh-my-zsh/plugins/fast-syntax-highlighting && git pull
else
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git  ~/.oh-my-zsh/plugins/fast-syntax-highlighting
fi

if [ -d ~/.oh-my-zsh/plugins/you-should-use ]; then
    cd ~/.oh-my-zsh/plugins/you-should-use && git pull
else
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ~/.oh-my-zsh/plugins/you-should-use
fi


if [ -d ~/.oh-my-zsh/custom/plugins/zsh-completions ]; then
    cd ~/.oh-my-zsh/custom/plugins/zsh-completions && git pull
else
    git clone --depth=1 https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
fi


if [ -d ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search ]; then
    cd ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search && git pull
else
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search
fi

######## STARSHIP ##########
curl -sS https://starship.rs/install.sh | sh
cp -f Files/starship/starship_3.toml ~/.config/starship.toml

######## REBOOT ZSH ##########
# source ~/.zshrc
echo -e "\nSudo access is needed to change default shell\n"
if chsh -s $(which zsh) && /bin/zsh -i -c 'omz update'; then
    echo -e "Installation Successful"
    sleep 5
    reboot
else
    echo -e "Something is wrong"
fi
exit

}

#FIX REPOS AND PPA'S *******************************************#
clear
mintsources
clear
sudo apt update
#*****************************************************#

# UPDATE & UPGRADE
cargo install topgrade
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.bashrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.bashrc

while [ $a -lt 1  ]
    do
        read -p "Do you wish to install ZSH+OH_MY_ZSH+STARSHIP? (Y/N) " yn
        case $yn in
            [Yy]* ) a=1;install=true;clear;;
            [Nn]* ) a=1;install=false;clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done

if $install; then
    install_ZSH
fi

sudo apt clean -y
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
sudo aptitude safe-upgrade -y

sudo bleachbit
sudo apt update -y
mintsources

sudo mainline-gtk

