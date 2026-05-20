# 📘 Guía de Instalación: Fedora Everything Netinstall (Minimal Core)

Esta guía detalla los pasos exactos y estrictos a seguir en la interfaz gráfica de Anaconda (el instalador clásico de Fedora) para preparar un sistema base ultra-ligero, seguro y **100% compatible con copias de seguridad de Timeshift**.

---

## 🥇 Checklist Crítico de Instalación en Anaconda

Antes de presionar el botón "Comenzar Instalación", asegúrate de configurar los siguientes apartados:

### 1. 🌐 Red y Nombre de Equipo (Network & Hostname)
* **Red:** Verifica que el interruptor de red (Ethernet/Wi-Fi) esté en **"Activado" (ON)**. Al usar la ISO *Netinstall*, la instalación fallará inmediatamente si no hay conexión a internet para descargar la base.
* **Hostname:** Escribe el nombre definitivo de tu máquina en el campo inferior (ej. `fedora-minimal` o `dev-workstation`) y haz clic en **Aplicar**.

### 2. 🌍 Fecha y Hora (Time & Date)
* Selecciona tu zona horaria exacta en el mapa. Esto es vital para que la sincronización del reloj en tiempo real (RTC) no falle durante los scripts de post-instalación.

### 3. 📦 Selección de Software (Software Selection) — *La purga del Bloatware*
Aquí es donde garantizamos un sistema puro sin interfaz gráfica ni aplicaciones basura:
* **Columna Izquierda (Entorno Base):** Selecciona **"Minimal Install"** (Instalación Mínima).
* **Columna Derecha (Complementos):** Asegúrate de que **NADA** esté marcado. Déjalo completamente vacío.

### 4. 💽 Destino de la Instalación (Btrfs Compatible con Timeshift)
> **⚠️ IMPORTANTE:** Fedora nombra los subvolúmenes Btrfs como `root` y `home` por defecto. Timeshift exige estrictamente la nomenclatura de Ubuntu (`@` y `@home`). 

Sigue estos pasos para configurarlo directamente desde el instalador:
1. Selecciona tu disco principal y marca **"Personalizado"** (Custom) en la configuración de almacenamiento. Haz clic en **Hecho**.
2. En la pantalla del particionador manual:
   * Haz clic en el enlace azul que dice *"Haga clic aquí para crearlas automáticamente"*. (Anaconda creará la estructura Btrfs base).
   * En el menú izquierdo, selecciona la partición raíz `/`.
   * En el panel derecho, busca el campo **Subvolumen** (por defecto dirá `root`). Bórralo y escribe únicamente **`@`**. Haz clic en **Actualizar Ajustes**.
   * En el menú izquierdo, selecciona el punto de montaje `/home`.
   * En el panel derecho, busca el campo **Subvolumen** (dirá `home`). Bórralo y escribe **`@home`**. Haz clic en **Actualizar Ajustes**.
3. Haz clic en **Hecho** en la parte superior y acepta el resumen de cambios.

### 5. 🚫 Cuenta Root (Root Account)
* Entra en esta sección y asegúrate de **Bloquear / Deshabilitar** la cuenta Root. La administración de nuestro sistema se hará de forma moderna y exclusiva a través de delegación con `sudo`.

### 6. 👤 Creación de Usuario (User Creation) — *El pase VIP*
* Introduce tu nombre completo, nombre de usuario deseado y una contraseña fuerte.
* **🔥 PASO CRÍTICO:** Marca obligatoriamente la casilla **"Hacer a este usuario administrador"** (Make this user administrator). Esto te ingresará al grupo `wheel`, otorgándote los permisos `sudo` necesarios para ejecutar el Script 1 en el primer reinicio.

---

## 🚀 Finalización
Una vez completados estos 6 puntos, haz clic en **Comenzar Instalación**. 

Al terminar el proceso y reiniciar el equipo, **no verás ninguna interfaz gráfica**. Te recibirá una pantalla de consola negra (TTY) conectada a internet, con la topología de discos perfecta y lista para que inicies sesión y ejecutes el script `1-system-core.sh`.