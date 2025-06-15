# 🐧 Fedora KDE Post-Install Framework – Versión Extendida

## 🎯 Objetivo del Proyecto

Este proyecto define un entorno reproducible y automatizado para configurar estaciones de trabajo Fedora 42+ con KDE Plasma. Está pensado para:

- Usuarios avanzados que reinstalan frecuentemente
- Equipos técnicos que necesitan estandarizar entornos
- Consultores y administradores que desean preparar máquinas listas para producción
- Integración futura con pipelines automatizados (Ansible, Kickstart, Packer, etc.)

---

## 📦 ¿Qué incluye?

- Módulo Bash reutilizable (`functions.sh`) para instalar y desinstalar paquetes
- Listas `.list` segmentadas por categoría: KDE base, utilidades, multimedia, etc.
- Soporte para grupos DNF (`@Fonts`), comodines (`xfce*`) y evaluación dinámica
- Dotfiles preconfigurados para shell (`.zshrc`), editor (`.nanorc`), terminal (`konsolerc`) y herramientas visuales (`fastfetch`)
- Logging detallado en `~/fedora_logs/pkg_manager.log`

---

## 📁 Estructura del Repositorio

```
Fedora/
├── KDE_PLASMA/
│   ├── dotfiles/                # Configuraciones personalizadas del entorno
│   │   ├── .zshrc
│   │   ├── .nanorc
│   │   ├── fastfetch_config.jsonc
│   │   ├── konsolerc
│   │   └── ...
│   ├── sources/
│   │   ├── functions/
│   │   │   └── functions        # Script modular principal
│   │   └── lists/
│   │       ├── kde_plasma.list
│   │       ├── utilities.list
│   │       ├── multimedia.list
│   │       └── ...
└── README.md
```

---

## ⚙️ Requisitos del sistema

- Fedora 42 o superior (idealmente KDE Spin)
- Conectividad a internet
- Paquetes disponibles:
  - `dnf`, `sudo`, `awk`, `xargs`, `grep`, `sort`
- (Opcional pero recomendado)
  - `oh-my-zsh`, `starship`, `fzf`, `flatpak`, `topgrade`, `powerlevel10k`

---

## 🚀 Guía de uso

### 1. Clonar el proyecto o copiar archivos localmente

```bash
git clone https://github.com/usuario/fedora-postinstall.git
cd fedora-postinstall/Fedora2/KDE_PLASMA
```

### 2. Incluir el módulo de funciones

Edita tu script principal o usa la terminal para incluir el archivo `functions`:

```bash
source sources/functions/functions
```

> Este script está protegido contra ejecución directa (usa `BASH_SOURCE`).

---

### 3. Ejecutar instalación de listas

Puedes instalar listas de paquetes, grupos o comodines de forma segura:

```bash
install_packages sources/lists/kde_plasma.list
install_packages sources/lists/utilities.list
install_packages sources/lists/multimedia.list
```

> Las listas están validadas para Fedora 42+ y pueden contener:
> - Paquetes individuales (`neovim`, `flatpak`)
> - Grupos (`@Fonts`)
> - Wildcards (`$(dnf list xfce*)`)

---

### 4. Eliminar bloatware KDE innecesario

```bash
remove_packages sources/lists/kde_bloatware.list
```

---

### 5. Aplicar dotfiles personalizados

Desde la carpeta `dotfiles/`, copia manualmente los archivos deseados:

```bash
cp dotfiles/.zshrc ~/.zshrc
cp dotfiles/.nanorc ~/.nanorc
cp dotfiles/konsolerc ~/.config/konsolerc
mkdir -p ~/.config/fastfetch && cp dotfiles/fastfetch_config.jsonc ~/.config/fastfetch/config.jsonc
```

> Puedes crear un script de setup personalizado si deseas automatizar esta parte.

---

## 📂 Detalle de listas disponibles

| Archivo                      | Descripción                                 |
|-----------------------------|---------------------------------------------|
| `kde_plasma.list`           | Paquetes mínimos de entorno KDE personalizado |
| `utilities.list`            | Herramientas CLI, GUI y productividad       |
| `multimedia.list`           | Soporte para audio, video y códecs          |
| `extra_apps.list`           | Apps Flatpak, Electron, utilidades varias   |
| `codecs.list`               | Paquetes multimedia avanzados (gstreamer, etc.) |
| `tools.list`                | Herramientas técnicas y de desarrollo       |
| `kde_bloatware.list`        | Lista de paquetes para eliminar (KDE Apps no deseadas) |

---

## 📈 Validación

✔️ Todos los archivos `.list` referenciados existen  
✔️ Los `@grupos` fueron convertidos a identificadores válidos (`Fonts`, `Multimedia`, etc.)  
✔️ Los `wildcards` fueron evaluados con `dnf list` dinámico  
✔️ No hay estructuras mal cerradas ni rutas rotas

---

## 🛠️ Logging

Cada instalación o remoción genera un log estructurado en:

```
~/fedora_logs/pkg_manager.log
```

Incluye:
- Timestamps
- Comandos ejecutados
- Resultados y errores
- Wildcards evaluados

---

## 🔐 Seguridad

- Se hace uso explícito y validado de `sudo` (con verificación previa)
- No existen comandos destructivos (`rm`, `dd`, `mkfs`, etc.)
- Puede integrarse a políticas de hardening empresarial si se ajusta

---

## 📚 Licencia

MIT License — Libre uso y modificación con atribución.

---

## 👨‍💻 Autor

**Gabriel Omaña**  
Initium · Consultoría Linux, Infraestructura y DevOps  
📫 gomana@initiumsoft.com

---