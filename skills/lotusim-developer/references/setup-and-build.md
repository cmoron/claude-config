# Setup & build (natif, Linux / WSL2)

LOTUSim est une stack **Linux only** (Ubuntu + ROS2 + Gazebo, install via apt dans
`launch/install_dep.sh`). Cible vérifiée : **WSL2 Ubuntu 24.04 + WSLg + GPU**, mais
tout vaut pour du Linux natif.

## ROS / Gazebo : quelle version

`launch/lotusim` détecte `VERSION_CODENAME` et choisit :

| Ubuntu | `ROS_DISTRO` | `GAZEBO_VERSION` | préfixe CLI |
|---|---|---|---|
| 24.04 noble | **jazzy** | **harmonic** | **`gz`** |
| 22.04 jammy | humble | harmonic | `gz` |

Le CI teste jazzy ET humble (`.github/workflows/ci.yml`) ; SonarCloud tourne sur
`ros:jazzy-desktop-full` + `harmonic`. `install_dep.sh` est **paramétré** par
`$ROS_DISTRO`/`$GAZEBO_VERSION` (pas codé en dur) — donc l'install native sur 24.04
en jazzy+harmonic est une cible supportée, et `gz` (Harmonic) est le bon préfixe
(jamais `ign`/Fortress, même si Humble par défaut viserait Fortress).

## Install

```bash
# Le wrapper fixe ROS_DISTRO/GAZEBO_VERSION depuis le codename, puis :
lotusim install         # sudo -E install_dep.sh  +  colcon build  +  install UI (node18/nvm)
lotusim install_lotus   # idem SANS l'UI (suffisant pour la sim ; pas de npm)
```

`install_dep.sh` (lancé en `sudo -E`) ajoute les dépôts ROS2 + Gazebo, puis installe
`gz-$GAZEBO_VERSION`, `ros-$ROS_DISTRO-ros-core` (+ `backward-ros`, `geographic-msgs`),
`python3-colcon-common-extensions`, `clang`, `libyaml-cpp-dev`, `libwebsocketpp-dev`,
`nlohmann-json3-dev`, `libreadline-dev`, `libcli11-dev`, et met clang en `c++` par défaut.

> `ros-core` est minimal : il **n'inclut pas `ros2` (la CLI)**. `rclcpp` + `ament_cmake`
> y sont (le build passe). Si tu as besoin de la CLI runtime : `apt install ros-$ROS_DISTRO-ros2cli`.

Si `install_dep.sh` est lancé hors du wrapper, lui passer les vars (il lit aussi
`$VERSION_CODENAME`, non exporté par défaut) :
`sudo ROS_DISTRO=jazzy GAZEBO_VERSION=harmonic VERSION_CODENAME=noble bash launch/install_dep.sh`

## Workspace colcon

LOTUSim attend un workspace colcon avec les packages sous `src/`. Le repo cloné à
plat n'en est pas un. Monter un workspace dédié (build isolé, repo source intact) :

```bash
mkdir -p ~/lotusim_ws/src
ln -sfn /chemin/vers/LOTUSim ~/lotusim_ws/src/LOTUSim
export LOTUSIM_WS=~/lotusim_ws
export LOTUSIM_PATH=$LOTUSIM_WS/src/LOTUSim
```

`physics/` **embarque xdyn en binaires prébuilts** (`libx-dyn.so`, `xdyn`,
`xdyn-for-cs`, `xdyn-for-me`) → le repo frère `LOTUSim-Xdyn` n'est PAS nécessaire au
build. Pas de `package.xml` à la racine : colcon découvre les packages (14) dans les
sous-dossiers (`systems/`, `interfaces/`, …). `lotusim build` = `colcon build
--merge-install` ; les plugins atterrissent dans `$LOTUSIM_WS/install/lib/lib*.so`.

## Le gotcha shell (zsh vs bash)

`/opt/ros/$ROS_DISTRO/setup.bash` est **bash-only**. Sous zsh il échoue
silencieusement (`complete: command not found`, `${BASH_SOURCE}` vide → il cherche
`setup.sh` dans le cwd, et **ne pose pas `AMENT_PREFIX_PATH`**) → le build colcon
ne trouve plus `builtin_interfaces`/`geometry_msgs`. Solutions :
- sourcer le bon script selon le shell : `setup.zsh` (zsh) / `setup.bash` (bash) ;
- ou tout passer par le wrapper `lotusim` (shebang bash) ;
- ou `bash -c '...'` pour les commandes ROS/colcon ponctuelles.

`scripts/setup_env.sh` gère ça (détecte `$ZSH_VERSION`/`$BASH_VERSION`). Le sourcer
hors `set -u` (les scripts ROS référencent des vars non posées).

## GPU sous WSLg

GPU compute (CUDA via `/dev/dxg`, `nvidia-smi`) marche, mais le **rendu OpenGL** tombe
par défaut sur `llvmpipe` (software) → Gazebo en diaporama. Forcer le driver Mesa
**d3d12** (qui mappe la vraie carte) :

```bash
export GALLIUM_DRIVER=d3d12
export MESA_LOADER_DRIVER_OVERRIDE=d3d12
glxinfo -B | grep -i renderer    # doit montrer "D3D12 (NVIDIA …)", pas llvmpipe
```

Prérequis : driver GPU "WSL" côté Windows (fournit `/usr/lib/wsl/lib/libd3d12*.so`,
`libdxcore.so`) et `mesa` récent (d3d12_dri.so). Déjà exporté par `setup_env.sh`.
Pour la **vérif headless**, ne jamais gater sur le rendu (EGL/OGRE2 fragile sous WSL).

## Docker (CI)

Le repo a un `dockerfile` (`FROM ghcr.io/sloretz/ros:${ROS_DISTRO}-desktop-full`,
`COPY . src/LOTUSim`, `lotusim install`). Pratique pour le CI, mais pour le rendu
GPU sous WSLg préférer l'install **native** (le rendu propre passe par WSLg, pas par
le software-GL d'un conteneur).
