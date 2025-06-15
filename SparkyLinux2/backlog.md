| Archivo / Carpeta                   | Estado                      | Descripción / Tareas pendientes                                               |
| ----------------------------------- | --------------------------- | ----------------------------------------------------------------------------- |
| `1-pre_install.sh`                  | ✅ Completo                  | Configura locales, teclado, PATH, logging                                     |
| `reset.sh`                          | ✅ Completo                  | Restaura entorno y ejecuta `1-pre_install.sh`                                 |
| `KDE_PLASMA/1-install.sh`           | ✅ Completo                  | Orquesta funciones modulares, limpieza y reinicio                             |
| `KDE_PLASMA/functions/init_env.sh`  | ✅ Completo                  | Logging, `require_cmd`, `run_cmd`, `log_*`                                    |
| `KDE_PLASMA/functions/functions.sh` | 🔧 En progreso              | Falta implementar funciones: `install_kde_desktop`, `install_base_apps`, etc. |
| `KDE_PLASMA/sources/kde.list`       | 🔜 Por crear                | Paquetes base de entorno KDE Plasma                                           |
| `KDE_PLASMA/sources/apps.list`      | 🔜 Por crear                | Apps básicas: firefox, vlc, htop, fastfetch                                   |
| `KDE_PLASMA/sources/media.list`     | 🔜 Por crear                | Codecs, herramientas de audio/video                                           |
| `KDE_PLASMA/sources/fonts.list`     | 🔜 Por crear                | Fuentes de sistema adicionales                                                |
| `KDE_PLASMA/sources/firmware.list`  | 🔜 Por crear                | Microcódigos y firmware para CPU/hardware                                     |
| `KDE_PLASMA/sources/network.list`   | 🔜 Por crear                | Red: openssh, curl, network-manager                                           |
| `KDE_PLASMA/2-post-install.sh`      | 🔜 Por desarrollar          | Aplicación de dotfiles, configuración de entorno gráfico                      |
| `KDE_PLASMA/3-style.sh`             | 🔜 Por desarrollar          | Aplicación de temas KDE, cursores, iconos                                     |
| `KDE_PLASMA/4-upgrade_sparky_78.sh` | ⏳ En revisión o placeholder | Script de upgrade entre versiones Sparky                                      |
| `KDE_PLASMA/pipewire.sh`            | ⏳ En revisión o placeholder | Activación/configuración de PipeWire                                          |
| `dotfiles/`                         | 🔧 Parcialmente listo       | Faltan definir qué archivos se copian y cómo (desde `2-post-install.sh`)      |
