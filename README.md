# arch-niri  (NEO-BRUTALISM)

Entorno de escritorio personal, modular y declarativo para **Arch Linux** construido sobre el compositor scrollable **Niri** y una interfaz completa en **Quickshell**, con generación dinámica de paleta de colores mediante **Matugen** y gestión automatizada de dotfiles con **GNU Stow**.

---

## Arquitectura del Repositorio

```text
~/Projects/arch-niri/
├── config/                  # Paquetes de configuración gestionados por GNU Stow
│   ├── bash/                # Respaldo minimalista para Bash
│   ├── clangd/              # Flags globales de C++20 para LSP
│   ├── ghostty/             # Terminal acelerada por GPU con recarga de tema en vivo
│   ├── matugen/             # Plantillas y hooks para sincronización global de colores
│   ├── mpv/                 # Reproductor multimedia de alta calidad (uosc + thumbfast)
│   ├── niri/                # Configuración modular del compositor Wayland (01 a 08)
│   ├── nvim/                # Configuración de Neovim (NvChad v2.5 + sincronización Matugen)
│   ├── quickshell/          # Barra, cajones cóncavos, OSD, Dock, Launcher y LockScreen
│   ├── yazi/                # Gestor de archivos en terminal con integración de directorio
│   └── zsh/                 # Shell interactivo modularizado en ~/.config/zsh/conf.d/
├── packages/                # Estado declarativo del software instalado
│   ├── appimages.tsv        # Registro de AppImages integradas al sistema
│   ├── pacman.txt           # Paquetes explícitos de repositorios oficiales
│   ├── paru.txt             # Paquetes explícitos de AUR
│   └── webapps.tsv          # WebApps empaquetadas con Pake
└── scripts/                 # Herramientas ejecutables enlazadas en ~/.local/bin/
    ├── appimage             # Instala, actualiza y elimina AppImages en ~/Applications
    ├── auto-permission-add  # Valida sintaxis, otorga +x y enlaza scripts en ~/.local/bin
    ├── auto-stow            # Limpia enlaces muertos, aplica Stow y registra scripts
    ├── install-system       # Despliegue integral automatizado para instalaciones limpias
    ├── set-wallpaper        # Aplica wallpaper (awww + swaybg blur) y regenera paleta (Matugen)
    ├── sync-packages        # Extrae paquetes explícitos hacia pacman.txt y paru.txt
    └── webapp               # Crea, instala, sincroniza y elimina WebApps con Pake
```

---

## Características Principales

* **Interfaz Reactiva en Quickshell:** Barra superior con ocultamiento automático en el Overview (`Mod + O`), cajones desplegables cóncavos con animación de extrusión (`Dashboard`, `MediaMenu`, `Wi-Fi`, `Bluetooth`, `Audio` y `Battery`), OSD unificado, dock inferior contextual (`RibbonDock`) y lanzador de aplicaciones con historial de frecuencia (`Launcher`).
* **Pantalla de Bloqueo (`LockScreen`):** Bloqueo nativo Wayland (`WlSessionLock`) con fondo desenfocado dinámico, caja de contraseña con celdas aleatorias y mini-tarjeta de control musical MPRIS integrada (exclusiva para **Spotify** y **SimpMusic**).
* **Estética Dinámica con Matugen:** Cambiar el wallpaper (`Mod + Shift + W`) regenera y aplica al instante la paleta de colores en **Niri, Quickshell, Ghostty, Neovim, Yazi, mpv y btop**.
* **Fondo Dual y Confort Visual:** Wallpaper nítido en el escritorio (`awww`), versión difuminada y oscurecida exclusiva para el backdrop del Overview (`swaybg` + `magick`) y ajuste automático de temperatura de color nocturna (`wlsunset`).

---

## Instalación desde Cero (Arch Linux limpio)

### 1. Requisitos previos
Asegúrate de tener una instalación base de Arch Linux con acceso a internet, `git` y `sudo` configurado para tu usuario:

```bash
sudo pacman -S --needed git base-devel
```

### 2. Clonar el repositorio
Clona el repositorio en la ruta estándar esperada por los scripts (`~/Projects/arch-niri`):

```bash
mkdir -p ~/Projects
git clone https://github.com/NobelC/arch-niri.git ~/Projects/arch-niri
cd ~/Projects/arch-niri
```

### 3. Ejecutar el instalador integral
Ejecuta `install-system` con `sudo` desde tu usuario normal (no como `root` directo). El script:
1. Instala todos los paquetes oficiales listados en `packages/pacman.txt`.
2. Compila e instala `paru` automáticamente si no está presente.
3. Instala los paquetes de AUR listados en `packages/paru.txt` (incluyendo `pake-cli`).
4. Ejecuta `auto-stow` para enlazar todos los dotfiles en `$HOME` y registrar los scripts en `~/.local/bin`.
5. Compila e instala las WebApps declaradas en `packages/webapps.tsv`.
6. Instala un **Pacman Hook** (`/etc/pacman.d/hooks/99-arch-niri-packages.hook`) para mantener las listas de paquetes sincronizadas automáticamente.
7. Habilita los servicios base (`NetworkManager`, `bluetooth`, `power-profiles-daemon`).

```bash
sudo bash ~/Projects/arch-niri/scripts/install-system
```

### 4. Cambiar el shell interactivo a Zsh y reiniciar sesión
```bash
chsh -s /usr/bin/zsh
```
Cierra sesión o reinicia el equipo e inicia **Niri** desde tu gestor de sesión (`ly`) o TTY (`niri-session`).

---

## Comandos y Scripts del Sistema

Todos los scripts dentro de `scripts/` son validados (`bash -n` / `shellcheck`) y enlazados en `~/.local/bin/`, por lo que están disponibles globalmente en la terminal.

### Gestión de Dotfiles y Scripts

| Comando | Descripción |
| :--- | :--- |
| `auto-stow` | Limpia symlinks rotos, enlaza todos los paquetes de `config/` hacia `$HOME` con GNU Stow y ejecuta `auto-permission-add`. |
| `auto-stow <paquete>` | Re-enlaza únicamente un paquete específico (ej. `auto-stow zsh` o `auto-stow quickshell`). |
| `auto-permission-add` | Valida la sintaxis de todos los archivos en `scripts/`, les otorga permisos `+x` y los enlaza en `~/.local/bin/`. |
| `auto-permission-add <script>` | Valida y enlaza únicamente el script indicado. |

### Gestión de AppImages (`appimage`)

Integra archivos `.AppImage` dentro de `~/Applications/`, extrae automáticamente su icono y entrada `.desktop` para el **Quickshell Launcher** y registra el estado en `packages/appimages.tsv`.

| Comando | Descripción |
| :--- | :--- |
| `appimage add <ruta.AppImage> [nombre]` | Copia el binario a `~/Applications/<slug>.AppImage`, extrae su icono y crea su lanzador en `~/.local/share/applications/`. |
| `appimage update <slug> <nuevo.AppImage>` | Reemplaza el binario existente por una nueva versión y actualiza su icono sin duplicar entradas. |
| `appimage remove <slug>` | Elimina el binario, el icono, el lanzador `.desktop` y su registro en `packages/appimages.tsv`. |
| `appimage list` | Muestra en tabla las AppImages gestionadas actualmente. |

### Gestión de WebApps (`webapp` + Pake)

Las WebApps se compilan como paquetes nativos aislados de Arch (`webapp-<slug>.pkg.tar.zst`) usando **Pake**, quedan registradas en `packages/webapps.tsv` y toman sus iconos de `~/Pictures/WebAppIcons/`.

| Comando | Descripción |
| :--- | :--- |
| `webapp add "<Nombre>" "<URL>" [icono] [flags]` | Compila, instala y registra una nueva WebApp. Si omites `[icono]`, busca automáticamente `<slug>.png/.svg/.ico` en `~/Pictures/WebAppIcons/`. |
| `webapp remove "<Nombre>"` | Desinstala el paquete de la WebApp del sistema y la elimina de `packages/webapps.tsv`. |
| `webapp sync` | Instala todas las WebApps declaradas en `packages/webapps.tsv` que aún no estén en el sistema. |
| `webapp list` | Muestra en tabla las WebApps registradas en el repositorio. |

**Ejemplos:**
```bash
# Coloca previamente ~/Pictures/WebAppIcons/gemini.png y ejecuta:
webapp add "Gemini" "https://gemini.google.com"

# Con dimensiones de ventana personalizadas:
webapp add "Spotify" "https://open.spotify.com" "" "--width 1280 --height 820"
```

### Paquetes y Sincronización

| Comando | Descripción |
| :--- | :--- |
| `sync-packages` | Extrae todos los paquetes instalados explícitamente (sin dependencias) hacia `packages/pacman.txt` y `packages/paru.txt`. Se ejecuta también automáticamente tras cada operación de `pacman`/`paru`/`webapp`. |

### Apariencia y Wallpapers

| Comando | Descripción |
| :--- | :--- |
| `set-wallpaper /ruta/imagen` | Aplica el wallpaper nítido con transición radial (`awww`), genera el fondo difuminado del Overview (`swaybg` + `magick`), actualiza el enlace de estado para `LockScreen` y regenera toda la paleta con **Matugen**. |

---

## Atajos de Teclado Principales (Niri)

| Atajo | Acción |
| :--- | :--- |
| `Mod + Return` | Abrir terminal (**Ghostty**) |
| `Mod + Alt + B` | Abrir navegador (**Firefox**) |
| `Mod + Space` | Abrir lanzador de aplicaciones (**Quickshell Launcher**) |
| `Mod + F` | Abrir gestor de archivos (**Yazi**) y permanecer en la ruta elegida al salir |
| `Mod + M` | Desplegar/ocultar reproductor multimedia (**MediaMenu**) |
| `Mod + Shift + W` | Abrir selector visual de wallpapers (**WallpaperPicker**) |
| `Mod + Alt + L` | Bloquear pantalla (**LockScreen**) |
| `Mod + W` | Monitor del sistema (**btop**) |
| `Mod + Q` | Cerrar ventana activa |
| `Mod + O` | Vista general de workspaces (**Overview**) |
| `Mod + H/J/K/L` o Flechas | Mover foco entre columnas y ventanas |
| `Mod + Ctrl + H/J/K/L` | Mover columnas y ventanas |
| `Mod + R` | Alternar ancho predefinido de columna (`33%`, `50%`, `66%`, `100%`) |
| `Mod + Alt + F` | Maximizar columna respetando barra y márgenes |
| `Mod + Shift + F` | Pantalla completa real |
| `Mod + V` | Alternar ventana flotante |
| `Mod + 1..9` | Cambiar al workspace `1..9` |
| `Alt + Shift` | Alternar distribución de teclado (`US` / `LATAM`) con indicador OSD |

---

## Notas Post-Instalación

* **Wallpapers:** Coloca tus fondos de pantalla en `~/Pictures/Wallpapers/` para que aparezcan en el carrusel (`Mod + Shift + W`).
* **Configuración local de Zsh:** Si necesitas variables o alias privados exclusivos de una máquina que no deban subirse a Git, créalos en `~/.config/zsh/local.zsh`.
* **Medir rendimiento de Zsh:** Ejecuta `ZSH_PROF=1 zsh -i -c exit` para perfilar el tiempo de carga de cada módulo en `conf.d/`.
