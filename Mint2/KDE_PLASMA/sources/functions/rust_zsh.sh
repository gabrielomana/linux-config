#!/bin/bash

# Install Rust
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  rm rustup-init.sh -rf
  source ~/.profile
  source ~/.cargo/env

  CARGO_BIN_DIR=$(echo $HOME/.cargo/bin)
  ROOT_SHELL=$(sudo cat /etc/passwd | grep "^root:" | awk -F: '{print $7}')
  case "$ROOT_SHELL" in
    "/bin/bash")
      echo "export PATH=\$PATH:$CARGO_BIN_DIR" | sudo tee -a /root/.bashrc > /dev/null
      ;;
    "/bin/zsh")
      echo "export PATH=\$PATH:$CARGO_BIN_DIR" | sudo tee -a /root/.zshrc > /dev/null
      ;;
    *)
      echo "Unknown root shell type: $ROOT_SHELL"
      ;;
  esac

# Install_ZSH
  install_ZSH

  function install_ZSH_ROOT() {
    clear

    echo -e "\nSe necesita acceso sudo para cambiar el shell predeterminado en root.\n"

    if sudo -v; then
        # Solicitar contraseña si no está en cache
        echo "Autenticación exitosa. Continuando con la configuración."

        if sudo chsh -s $(which zsh) root; then
            echo "Zsh en root configurado con éxito."

            # Actualizar oh-my-zsh en root
            sudo /bin/zsh -i -c 'omz update'

            # Configuración de Starship en root
            sudo sh -c "$(curl -fsSL https://starship.rs/install.sh)"
            sudo wget https://raw.githubusercontent.com/gabrielomana/MyStarships/main/1_starship_powerline_1col_nord_aurora.toml -O /root/.config/starship.toml

            # Copiar archivos de configuración para root
            sudo cp -f dotfiles/.zshrc /root/
            sudo mkdir -p /root/.cache/zsh/

            if sudo [ -f /root/.zcompdump ]; then
                sudo mv /root/.zcompdump* /root/.cache/zsh/
            fi

            # Reiniciar Zsh para root
            sudo su -c "chsh -s /bin/zsh root"
            CARGO_BIN_DIR=$(echo $HOME/.cargo/bin)
            echo "export PATH=\$PATH:$CARGO_BIN_DIR" | sudo tee -a /root/.zshrc > /dev/null

        else
            echo -e "Algo ha salido mal al configurar Zsh para root.\n"
        fi
    else
        echo -e "No se pudo autenticar. Por favor, inténtalo nuevamente.\n"
    fi
}


function install_ZSH() {
    clear

    # Verificar si Zsh, Git y Wget ya están instalados
    if command -v zsh &> /dev/null && command -v git &> /dev/null && command -v wget &> /dev/null; then
        echo -e "Zsh, Git, y Wget ya están instalados.\n"
    else
        # Instalar Zsh, Git y Wget si no están instalados
        if sudo apt install zsh git wget -y; then
            echo -e "Zsh, Git y Wget instalados con éxito.\n"
        else
            echo -e "Por favor, instala los siguientes paquetes primero y luego vuelve a intentarlo: zsh, git, wget.\n" && exit
        fi
    fi

    # Respaldar .zshrc actual
    if mv -n ~/.zshrc ~/.zshrc-backup-$(date +"%Y-%m-%d"); then
        echo -e "Se ha respaldado el .zshrc actual en .zshrc-backup-fecha.\n"
    fi

    # Instalar oh-my-zsh si no está instalado
    clear
    if [ -d ~/.oh-my-zsh ]; then
        echo -e "oh-my-zsh ya está instalado.\n"
        git -C ~/.oh-my-zsh remote set-url origin https://github.com/ohmyzsh/ohmyzsh.git
    else
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    fi
    sleep 5

    # Copiar archivos de configuración
    clear
    cp -f dotfiles/.zshrc ~/
    mkdir -p ~/.cache/zsh/

    if [ -f ~/.zcompdump ]; then
        mv ~/.zcompdump* ~/.cache/zsh/
    fi
    sleep 5

    # Cambiar la ruta de los plugins a una ubicación global
    plugins_path="/usr/share/oh-my-zsh/custom/plugins/"

    clear
    plugins=(
        "zsh-autopair"
        "zsh-autosuggestions"
        "zsh-completions"
        "zsh-history-substring-search"
        "zsh-syntax-highlighting"
        "you-should-use"
        "fzf-tab"
    )

    for plugin in "${plugins[@]}"; do
        if [ -d "$plugins_path$plugin" ]; then
            cd "$plugins_path$plugin" && git pull
        else
            git clone --depth=1 "https://github.com/zsh-users/$plugin" "$plugins_path$plugin"
        fi
    done

    # Instalar fzf para fzf-tab
    sudo apt install fzf -y

    sleep 5

    # Instalar y configurar Starship
    clear
    curl -sS https://starship.rs/install.sh | sh
    wget https://raw.githubusercontent.com/gabrielomana/MyStarships/main/1_starship_powerline_1col_nord_aurora.toml -O ~/.config/starship.toml
    sleep 5

    # Reiniciar Zsh
    clear
    echo -e "\nSe necesita acceso sudo para cambiar el shell predeterminado.\n"
    if chsh -s $(which zsh) && /bin/zsh -i -c 'omz update'; then
        echo "Zsh en usuario: OK"
        echo "Instalando Zsh en root..."
        sleep 3
        #instalar_ZSH_ROOT
    else
        echo -e "Algo ha salido mal.\n"
    fi
    return
}