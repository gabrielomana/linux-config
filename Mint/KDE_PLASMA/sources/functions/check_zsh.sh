#!/bin/bash

# Ruta del directorio de plugins de Oh My Zsh
custom_plugins_path="/usr/share/oh-my-zsh/custom/plugins/"

# Archivo de registro
log_file="verification_log.txt"

# Función para imprimir mensajes en el archivo de registro
log_message() {
    echo "$1" | tee -a "$log_file"
}

# Verificar si Oh My Zsh está cargado
if grep -q "source \$ZSH/oh-my-zsh.sh" ~/.zshrc; then
    log_message "Oh My Zsh está cargado correctamente en ~/.zshrc"
else
    log_message "Error: Oh My Zsh no está cargado correctamente en ~/.zshrc"
fi

# Verificar si la ruta de los plugins existe
if [ -d "$custom_plugins_path" ]; then
    log_message "La ruta $custom_plugins_path existe."
    
    # Lista de plugins a verificar
    plugins_to_check=(
        "zsh-autopair"
        "zsh-autosuggestions"
        "zsh-completions"
        "zsh-history-substring-search"
        "zsh-syntax-highlighting"
        "you-should-use"
        "fzf-tab"
    )

    # Verificar cada plugin
    for plugin in "${plugins_to_check[@]}"; do
        plugin_path="$custom_plugins_path$plugin"
        if [ -d "$plugin_path" ]; then
            log_message "El plugin $plugin se encuentra en $custom_plugins_path"
        else
            log_message "Error: El plugin $plugin no se encuentra en $custom_plugins_path"
        fi
    done
else
    log_message "Error: La ruta $custom_plugins_path no existe."
fi

log_message "Verificación completa."
