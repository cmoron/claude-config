---
name: lotusim-developer
description: Construire, lancer et contribuer à LOTUSim (simulateur maritime ROS2 + Gazebo + xdyn de Naval Group). Charger pour installer/builder LOTUSim, ajouter un véhicule/modèle, lancer une simulation avec physique, débugger un vaisseau qui ne bouge pas, ou préparer une PR. Indispensable avant toute commande `lotusim`/`gz` sur ce projet — l'archi (physique = co-sim xdyn externe, rendu Gazebo OU Unity) piège quiconque ne la connaît pas.
---

# LOTUSim developer

LOTUSim = simulateur naval multi-agents **open-source (EPL-2.0)** de Naval Group.
Stack : **ROS2 + Gazebo** (rendu/orchestration) + **xdyn** (dynamique des corps, en
co-simulation). Repo : `github.com/naval-group/LOTUSim`. Fork de travail :
`cmoron/LOTUSim` (origin) ← `naval-group/LOTUSim` (upstream).

Ce skill condense le savoir non-évident vérifié sur le terrain. **Lis d'abord les
6 pièges ci-dessous** — chacun coûte des heures si on l'ignore.

## Les 6 pièges (à connaître AVANT de coder)

1. **La physique est un serveur xdyn EXTERNE, pas un plugin gz.** Le
   `physics_interface_plugin` de Gazebo est un *client websocket* qui se connecte à
   un `xdyn-for-cs` lancé séparément (un par vaisseau, sur un port TCP : 12345,
   12346…). **`lotusim run` ne lance que `gz` — PAS xdyn.** Sans serveur xdyn qui
   écoute, le vaisseau spawn et se rend mais **n'a aucune dynamique** :
   `XdynWebsocket::onFail` → `loadVessel: Loading failed, Removing physics`.
   → Pour rouler avec physique : `scripts/run_demo_world.sh` ou voir
   `references/run-and-verify.md`.

2. **Beaucoup de modèles n'ont AUCUN `<visual>`** (juste de la collision). Les
   navires comme `wamv`, `dtmb_hull`, `lrauv` se rendent dans **Unity**
   (`render_plugin` → ROS2 → client Unity), donc dans la **GUI Gazebo ils sont
   invisibles** (toggle *Entity Tree → clic droit → View → Collisions* pour les
   voir). Pour qu'un vaisseau s'affiche directement dans gz, lui donner un
   `<visual>` — c'est un pattern LOTUSim légitime (cf. `fremm`, `commando`).

3. **Ubuntu 24.04 (noble) → ROS2 Jazzy + Gazebo Harmonic.** Pas Humble (= 22.04).
   Harmonic ⇒ préfixe **`gz`** (`gz sim`, `gz.msgs.*`), jamais `ign`/Fortress. Le
   wrapper `launch/lotusim` auto-détecte le codename et fixe `ROS_DISTRO`/
   `GAZEBO_VERSION` tout seul. Install : `lotusim install`. → `references/setup-and-build.md`.

4. **Les scripts ROS sont bash-only.** `source /opt/ros/jazzy/setup.bash` casse sous
   zsh (`complete: command not found`, `${BASH_SOURCE}` vide → mauvais chemins, et
   `CMAKE_PREFIX_PATH`/`AMENT_PREFIX_PATH` non posés → build qui ne trouve pas
   `geometry_msgs`). Sous zsh : sourcer `setup.zsh`, ou tout passer par le wrapper
   `lotusim` (shebang `#!/bin/bash`). Utiliser `scripts/setup_env.sh` (shell-aware).

5. **`pkill -f "gz sim"` / `pkill xdyn-for-cs` se SUICIDENT.** Le pattern matche la
   ligne de commande de ton propre shell (qui contient ce texte) → auto-kill
   (exit ~144). Capturer les PID (`pid=$!`) et `kill "$pid"`, ou utiliser un
   `trap cleanup EXIT` (comme dans `run_demo_world.sh`).

6. **En co-sim, la POUSSÉE ne vient ni du yaml `commands:` ni du `waypoint_follower`.**
   `xdyn-for-cs` **ignore** le bloc `commands:` du yaml. Les consignes de thrusters se
   **publient** sur le topic ROS2 `/<world>/vessel_cmd_array`
   (`lotusim_msgs/msg/VesselCmdArray`) : chaque `VesselCmd.cmd_string` est un JSON
   `{"<thruster>(rpm)": <val>, "<thruster>(P/D)": <val>}` que le
   `physics_interface_plugin` forwarde tel quel à xdyn. Sans publisher → défaut câblé
   `<thruster>(rpm)=2.0` → poussée quasi nulle (warning `Wageningen … n too small`).
   Le `waypoint_follower` n'émet QUE du status : c'est un mode **cinématique** séparé,
   **aucun world ne le combine** avec `physics_engine_interface`. → Bouger un vaisseau
   SOUS PHYSIQUE = un petit nœud rclpy qui publie sur `vessel_cmd_array` (cf.
   `references/run-and-verify.md`).

(Bonus WSL2/WSLg : le rendu OpenGL tombe sur `llvmpipe` (soft) par défaut ; forcer
`GALLIUM_DRIVER=d3d12` pour la **GUI gz** accélérée (déjà dans `setup_env.sh`). ⚠️ Mais le
frontend **Unity HDRP rend en Vulkan**, et WSLg n'expose aucun device Vulkan GPU (lavapipe
CPU est refusé par Unity) → HDRP KO sans **Dozen** ; détail + pont gz→Unity dans
`references/render-bridge-and-coordinates.md`.)

(Bonus macOS : sur Apple Silicon le mur Vulkan/HDRP de WSL disparaît — Unity rend en **Metal**.
Approche validée = conteneur amd64 émulé (Rosetta) headless + Unity natif comme client de rendu.
Pièges génériques : xdyn x86-64 → Rosetta (pas arm64), `FASTDDS_BUILTIN_TRANSPORTS` UDPv4 →
**DEFAULT** (SHM, sinon découverte abonné-avant-publisher KO), `ros_tcp_endpoint` mono-thread
dont l'`accept()` est affamé sous charge → **connect-first**, la scène applicative Photon
(`GameManager`/`Launcher`) qui détruit le `LotusimConnector` quand on joue standalone, socket
Unity zombie qui coince le proxy Docker. § 6 de `render-bridge-and-coordinates.md`.)

## Quick start

```bash
# 1. Environnement (à sourcer avant tout — shell-aware bash/zsh, GPU, chemins gz)
source ~/lotusim_ws/setup_env.sh          # cf. scripts/setup_env.sh à adapter au workspace

# 2. Install (une fois) — ROS2 Jazzy + Gazebo Harmonic en natif, puis colcon build
lotusim install            # deps (sudo) + build + UI ; ou `lotusim install_lotus` (sans UI)
lotusim build              # rebuild seul (sous bash) ; `clean_build` pour repartir propre

# 3. Lancer un monde AVEC physique (xdyn server(s) + gz) — c'est le piège n°1
~/lotusim_ws/run_demo_world.sh xdyn_multithread_test.world dtmb_hull/dtmb-xdyn.yml 12345 12346
#   --headless en dernier arg pour sans GUI

# 4. Lancer un monde SANS physique (gz seul — debug rendu/plugins)
lotusim run --gui <world>.world      # GUI ;  sans --gui = headless (gz sim -s)
```

Succès physique = log `PhysicsInterfacePlugin::loadVessel: ... physics in domain
Surface init completed` + `XdynWebsocket::onOpen`. Échec = `onFail` / `unable to
connect` → aucun serveur xdyn sur le port, ou port/uri qui ne matchent pas le world.

## Ajouter un véhicule (le cas de contribution type)

Un modèle vit dans `assets/models/<name>/` : `model.config`, `model.sdf` (SDF 1.10,
minimal : collision + capteurs ; ajouter un `<visual>` pour le voir dans gz),
`<name>.yaml` (**modèle xdyn** : inerties, added-mass, damping, propulsion — c'est
là qu'est la dynamique), `meshes/` (.dae visual + une .stl pour l'hydrostatique xdyn,
générables via **Blender 4.5 + blender-mcp** — cf. `references/model-world-anatomy.md`).
Le véhicule est wiré dans un world via `<include>` + `<lotus_param>`
(`physics_engine_interface` → port xdyn + thrusters ; `waypoint_follower` ;
`render_interface`). Templates complets + protocole : **`references/model-world-anatomy.md`**.

Workflow PR (`CONTRIBUTING.md`) : issue (label `new_model`) → s'annoncer → fork →
implémenter → tester → PR référençant l'issue. **Licence EPL-2.0** : ne jamais
vendoriser d'assets GPL (ex. ArduPilot SITL_Models) ou sans droit de redistribution
(ex. CAD constructeur) — réauthoring à partir de dimensions publiques uniquement.

## Références (charger selon le besoin)

- `references/setup-and-build.md` — install native (Jazzy/Harmonic), workspace colcon,
  GPU WSLg, gotcha shell, ce que fait `setup_env.sh`, Docker (CI).
- `references/model-world-anatomy.md` — anatomie `model.config`/`model.sdf`/`<name>.yaml`,
  bloc `<lotus_param>`, visual-vs-Unity, templates copiables, génération des meshes via
  Blender 4.5 + blender-mcp (gotcha WSLg : fenêtre non-maximisée `-p`).
- `references/run-and-verify.md` — orchestration xdyn co-sim, `xdyn-for-cs` (args, ports),
  vérif headless, oracle de déplacement, réf `scenario_launch.sh`.
- `references/ecosystem-and-architecture.md` — où trouver quoi : index du **wiki** (15 pages),
  le repo **`LOTUSim-generic-scenario`** (installeur auto + run config-driven + `DIAGRAMS.md` +
  Player Unity prébuildé), les 3 repos Unity, le fork de travail.
- `references/render-bridge-and-coordinates.md` — le flux gz↔xdyn↔Unity : commander
  (`<thrusters>` vs `<control_surfaces>` à angle), conventions de repère (NED/ENU/Unity,
  ordre `qr,qi,qj,qk`, `Z→-Y`), pont `render_plugin`/Addressables/namespace, **mur HDRP sous
  WSLg** (→ Dozen), **bring-up macOS** (conteneur amd64 Rosetta + Unity Metal : SHM,
  connect-first, redirection de scène Photon, socket zombie), gotcha mesh (`.dae` Blender cassé
  → FBX `bake_space_transform`).

## Scripts (autoportants, à adapter au chemin du workspace)

- `scripts/setup_env.sh` — env natif complet (suppose `~/lotusim_ws` avec `src/LOTUSim`).
- `scripts/run_demo_world.sh` — lance N serveurs xdyn puis gz, cleanup par PID/trap.
