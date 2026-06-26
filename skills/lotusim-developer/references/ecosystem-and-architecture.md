# LOTUSim — écosystème & docs (où trouver quoi)

Le core `naval-group/LOTUSim` ne se suffit pas : le savoir et le runnable sont éclatés
sur le **wiki** + un repo de **scénario** + 3 repos **Unity**. Cette page est l'index.

## Le wiki (`github.com/naval-group/LOTUSim/wiki`)

Clonable en git : `git clone https://github.com/naval-group/LOTUSim.wiki.git`. 15 pages.
Les plus utiles :

| Page | Contenu |
|---|---|
| **Xdyn-User-Guide** (95 K, la bible) | repères NED + body (X-fwd, Y-stbd, Z-down), convention de rotation `Z/Y/X` `[psi,theta',phi'']` (seule supportée), quaternions `qr,qi,qj,qk`, mesh (normales vers le fluide), surfaces de contrôle (`hydrodynamic polar`), hélices (Kt/Kq, prop+rudder, Wageningen B), exemple yaml complet, unités (piège : `ton` = 907 kg). |
| **Core-Development** | plugin `render_plugin` (SDF), bloc `<lotusim_param>` (`render_interface`/`physics_engine_interface`), **et la conversion de repère gz↔Unity `Z→-Y`** (cf. `render-bridge-and-coordinates.md`). |
| **Physics-Implementation** | co-sim xdyn, sync des vagues Unity↔xdyn (vagues spatialement périodiques, période = taille de répétition Unity HDRP). |
| **Platform_Model_Characteristics** | fiches par modèle (dimensions, masses, repère). |
| **Gazebo-Setup** | `model.config`/`model.sdf`, formats mesh (STL/DAE/OBJ), **`<visual>` optionnel car Unity rend** (→ invisibles dans la GUI gz). |
| **Getting-Started** | survol (3 étapes : sdf → moteur physique → Unity) — **léger**, le vrai walkthrough est dans `LOTUSim-generic-scenario` ci-dessous. |
| Unity-Setup / Unity-Development | scripts `lotusim_interface` (`common.cs` = conversion de pose, `LotusimConnector.cs`). |
| Xdyn-Setup / Xdyn-Development | build xdyn, modules, workflow PR (feature branch courte liée à une issue, pas de commit direct sur master, CI obligatoire). |

## `naval-group/LOTUSim-generic-scenario` — le walkthrough runnable

C'est le **workspace de scénario prêt à l'emploi** au-dessus du core (couvre ce que le
Getting-Started du wiki survole). Contient :
- **installeur automatisé** `install_core_and_generic_scenario.sh` : détecte Ubuntu→ROS
  (22.04→Humble, 24.04→Jazzy), clone le core dans `~/lotusim_ws`, configure `.bashrc`,
  `lotusim install`, build le workspace (idempotent).
- **run config-driven** : `src/simulation_run/executable/scenario_launch.sh --config <x>.json`
  (ex. `defenseScenario.json`) ; spawn d'agents (formats de pose initiale documentés) ;
  **contrôle propulseurs via topic ROS** (= le `vessel_cmd_array`, cf. piège #6).
- **doc archi sérieuse** `doc/DIAGRAMS.md` : package tree, class/sequence diagrams (agents,
  `simulation_run`), séquence de lancement de `defenseScenario`, nodes/topics/actions.
- un **Player Unity Linux PRÉBUILDÉ** : `lotusim_unity_executables/lotusim_scenario_linux/`
  (`lotusim_scenario.x86_64` + `UnityPlayer.so` + `_Data`), scène = `defenseScenario`.
  ⚠️ Rend du HDRP → sous WSLg il heurte le même mur Vulkan que l'Éditeur (cf.
  `render-bridge-and-coordinates.md` § « Mur HDRP sous WSLg »).

## Les 3 repos Unity (`naval-group/…`)

| Repo | Rôle |
|---|---|
| `LOTUSim-Unity-modules` | projet Unity principal (scènes, `lotusim_interface`). README épingle 2022.3.18f1 → ouvrir avec **2022.3.62f2** (patch CVE-2025-59489). |
| `LOTUSim-Unity-ros-tcp-endpoint` | récepteur du pont (fork Unity Robotics ROS-TCP-Endpoint, ros2). Build : `colcon build --merge-install --packages-select ros_tcp_endpoint`. |
| `LOTUSim-Unity-custom-hdrp` | fork HDRP (rendu de la mer/physique). En prod le manifest peut pointer la HDRP **registry** (14.0.x) plutôt que ce fork. |

## Notre fork de travail

`origin = cmoron/LOTUSim` ← `upstream = naval-group/LOTUSim`. Branche `demo/focus-v2` :
modèle voilier Focus V2 + worlds de démo, support `<control_surfaces>`, et le fix du
round-trip quaternion (cf. mémoire projet du talk pour le détail PR-readiness).
