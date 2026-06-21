# Lancer avec physique & vérifier

## L'archi de co-simulation (le point clé)

```
   xdyn-for-cs (serveur websocket, 1 par vaisseau)        gz sim (Gazebo)
   ws://127.0.0.1:12345  <───────────────────────────  physics_interface_plugin (client)
        ^                                                       │
        │ dynamique (xdyn lit <name>.yaml)                      │ pose, waypoint, capteurs
```

- `physics_interface_plugin` (dans gz) est un **client** ; il lit l'`<uri>` du
  `<lotus_param><physics_engine_interface>` du world et se connecte.
- `xdyn-for-cs` (binaire prébuilt dans `physics/`) est le **serveur** : il calcule la
  dynamique 6 DOF à partir du `<name>.yaml`. **Un process par vaisseau**, un port
  unique chacun (12345, 12346, …).
- `lotusim run` **ne lance QUE gz**. Il faut démarrer xdyn à part, sinon :
  `XdynWebsocket::onFail: Failed ws://… → loadVessel: Loading failed, Removing physics`.

### Lancer xdyn-for-cs

```bash
xdyn-for-cs <model>.yaml --address 127.0.0.1 --port 12345 --dt 0.2
#   --dt 0.2 = pas de temps (cf. scenario_launch.sh) ; -s rk4 par défaut (euler/rkck dispo)
#   --verbose pour voir les échanges ; -w pour le détail websocket
```

Orchestrateur de référence (multi-agents, le "vrai" lanceur) :
`LOTUSim-generic-scenario/src/simulation_run/executable/scenario_launch.sh`
(lance un `xdyn-for-cs agent.yml --port $port --dt 0.2` par agent, puis gz, et
`pkill -f xdyn-for-cs` au cleanup).

### Helper fourni

`scripts/run_demo_world.sh <world> <model-rel.yml> <port…> [--headless]` :
lance un serveur xdyn par port, puis `gz` (GUI par défaut), et **tue les serveurs par
PID via `trap`** (pas de `pkill` auto-suicidaire). Exemple :

```bash
run_demo_world.sh xdyn_multithread_test.world dtmb_hull/dtmb-xdyn.yml 12345 12346
```

## Lancer gz (Harmonic)

```bash
lotusim run <world>.world          # headless (gz sim -s) — défaut
lotusim run --gui <world>.world    # avec GUI
# direct : gz sim -s -v3 -r <world>   (-s serveur seul, -r run, -v3/-v4 verbosité)
```

Le wrapper pose `GZ_SIM_SYSTEM_PLUGIN_PATH=install/lib`, `GZ_SIM_RESOURCE_PATH=
assets/models`. Préfixe **`gz`** (Harmonic), pas `ign`.

## Vérifier (oracle = déplacement)

Pour "ça flotte + ça bouge", l'oracle robuste est le **déplacement mesuré dans la
sim** (pas le rendu — EGL/OGRE2 fragile sous WSL ; ne jamais gater pass/fail dessus).
Boucle headless :

```
build → valider SDF (gz sdf -k <file>) → [xdyn server(s)] → spawn headless (gz sim -s -r)
      → lire pose début/fin → assert dist > seuil → (artefact : plot de trajectoire)
```

Signaux de log à asserter :
- `physics in domain Surface init completed` + `XdynWebsocket::onOpen` → physique OK ;
- `onFail` / `unable to connect` → pas de serveur xdyn / port-uri qui ne matchent pas ;
- `Failed to load system plugin` → chemin plugin (`GZ_SIM_SYSTEM_PLUGIN_PATH`) ou build ;
- `dist ≈ 0` → a coulé (mauvaise hydrostatique) ou pas de poussée (aucune consigne sur `vessel_cmd_array`).

### Source de poussée en co-sim (PIÈGE n°6) : `vessel_cmd_array`, pas le yaml ni le waypoint

`xdyn-for-cs` **ignore** le bloc `commands:` du yaml. La poussée se **publie** sur le
topic ROS2 `/<world>/vessel_cmd_array` (`lotusim_msgs/msg/VesselCmdArray`) : le
`physics_interface_plugin` souscrit et forwarde `VesselCmd.cmd_string` (JSON) à xdyn.
Clés du `cmd_string` = `"<thruster>(<param>)"`, params `rpm` / `P/D` / `beta` ; les
noms doivent matcher `<thrusters>` du world ET les actionneurs du yaml. Sans publisher
→ défaut câblé `rpm=2.0` → poussée quasi nulle. Le `waypoint_follower` n'est PAS cette
source (status seul, mode cinématique). Publisher minimal :

```python
# pub_thrust.py — fait bouger un vaisseau sous physique (co-sim)
import json, rclpy
from rclpy.node import Node
from lotusim_msgs.msg import VesselCmd, VesselCmdArray
rclpy.init(); n = Node("thrust_pub")
pub = n.create_publisher(VesselCmdArray, "/lotusim/vessel_cmd_array", 10)
cmd = json.dumps({"PSthruster(rpm)": 250.0, "SBthruster(rpm)": 250.0})
n.create_timer(0.1, lambda: pub.publish(
    VesselCmdArray(cmds=[VesselCmd(vessel_name="blueboat", cmd_string=cmd)])))
rclpy.spin(n)
```

### Lire la pose (oracle) → il faut le `SceneBroadcaster`

Les worlds LOTUSim rendent dans Unity et **n'embarquent pas**
`gz-sim-scene-broadcaster-system` → aucun topic de pose (et invisible dans la GUI gz).
Pour mesurer le déplacement (et rendre dans gz), ajouter au world :
`<plugin filename="gz-sim-scene-broadcaster-system" name="gz::sim::systems::SceneBroadcaster"/>`,
puis lire `/world/<world>/dynamic_pose/info` (`gz topic -e … --json-output`), extraire
la pose du vaisseau (jq) et asserter le déplacement horizontal.

## Pièges runtime

- **Shell** : lancer via le wrapper `lotusim` (bash) ou sourcer `setup.zsh` sous zsh.
- **pkill suicidaire** : `pkill -f "gz sim"`/`xdyn-for-cs` matche ta propre commande →
  auto-kill (exit ~144). Capturer `$!` et `kill`, ou `trap` (cf. run_demo_world.sh).
- **Ports** : un par vaisseau ; doivent matcher les `<uri>` du world.
- **GPU** : `GALLIUM_DRIVER=d3d12` sinon llvmpipe (rendu logiciel).
- **Gravity 0** dans les worlds : normal, xdyn fait toute la dynamique.
- **`set -u`** : ne JAMAIS l'activer avant de sourcer l'env ROS (`setup.bash` référence
  des vars non-définies → le script meurt en silence, exit 1 sans aucune sortie).
- **`gz sdf -k`** : valide un `model.sdf` mais **échoue sur un world** avec `<include>`
  (`Unable to find uri[model://…]`, pas de find-callback) → valider le world par un
  spawn, pas par `-k`.
- **Mesh de travers ("crabe")** : convention LOTUSim = avant du mesh sur **+y** (cf.
  `references/model-world-anatomy.md`).
- **Screenshot GUI** : le service `/gui/screenshot` veut un **répertoire** (il y dépose
  un PNG horodaté), pas un chemin de fichier.
