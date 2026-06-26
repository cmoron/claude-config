# Flux de données gz ↔ xdyn ↔ Unity, conventions de repère, et rendu

Le plan de données d'un vaisseau LOTUSim a trois flux. Les connaître évite les bugs
silencieux d'orientation et les « connecté mais rien ne s'affiche ».

```
              commandes (out)                    état (in)                   rendu (out)
ROS2 vessel_cmd_array ──► gz physics_engine ──► xdyn ──► gz entity pose ──► render_plugin ──► Unity
   (thrusters / control_surfaces)   (websocket)         (quaternion NED→ENU)   (ROS2/TCPUDP)   (Z→-Y)
```

## 1. Commander un vaisseau (commandes → xdyn)

xdyn **ignore** le bloc `commands:` du yaml. Les consignes se **publient** sur
`/<world>/vessel_cmd_array` (`lotusim_msgs/msg/VesselCmdArray`) ; chaque
`VesselCmd.cmd_string` est un JSON `{"<signal xdyn>": <valeur>}` forwardé tel quel.

- **Hélices** (`<thrusters>` dans le `<lotus_param>`) → signaux `<name>(rpm)`, `<name>(P/D)`,
  `<name>(beta)`. Sans publisher → défaut câblé `(rpm)=2.0` ≈ poussée nulle.
- **Actuateurs à ANGLE** (voiles, safran, ailerons) → ce sont des *force models* xdyn
  (`hydrodynamic polar`) commandés par leur **signal complet** `<force model>(<angle command>)`,
  p.ex. `mainsail(sail)`, `rudder(angle)`. ⚠️ Le template de commande upstream se construit
  **uniquement** depuis `<thrusters>` → un force-model à angle n'a pas de commande par défaut
  et `commands.at(<clé>)` **lève** avant le 1er setpoint ROS. Le fork `cmoron/LOTUSim`
  `demo/focus-v2` ajoute un bloc **`<control_surfaces>`** (chaque entrée = le signal complet,
  seedé à 0.0) à côté de `<thrusters>`. Bouger sous physique = un nœud rclpy qui publie sur
  `vessel_cmd_array` (cf. `run-and-verify.md`).

## 2. État de retour (xdyn → gz) — conventions de repère

- **xdyn = repère NED** (North-East-Down) ; body = X-avant, Y-tribord, Z-bas ; rotation
  `Z/Y/X` `[psi, theta', phi'']` (seule convention supportée).
- **Quaternion** : ordre `qr, qi, qj, qk` (réel d'abord). `xdyn_websocket.cpp` lit le message
  et **doit** mapper ces champs nommés dans le bon ordre positionnel `Quaterniond(qr,qi,qj,qk)`
  AVANT la conversion de repère — sinon un yaw revient en roll et le cap ne s'accumule jamais
  (invisible à l'orientation identité). Send (`getNewState`) et receive doivent être inverses.
- **NED → ENU** : `quatNedToEnu()` / `vecNedToEnu()` convertissent l'état NED de xdyn vers le
  repère **ENU droitier (Z-up)** de Gazebo. C'est une étape **séparée**, en aval du parsing.

## 3. Rendu (gz → Unity)

Le rendu LOTUSim de prod est **Unity**, pas la GUI gz (beaucoup de modèles n'ont aucun
`<visual>` → invisibles dans gz). Pont :

- Plugin **world** : `<plugin filename="render_plugin" name="lotusim::gazebo::RenderPlugin">`
  avec `<connection_protocol>` = **`ROS2`** ou **`TCPUDP`** (seules valeurs acceptées).
- Par vaisseau, dans `<lotus_param>` : `<render_interface><publish_render>true</publish_render>`
  `<renderer_type_name>NAME</renderer_type_name></render_interface>`.
- En ROS2, le nœud gz est **namespacé par le nom du world** → topics
  `/<world>/renderer_cmd` (`RendererCmd` : CREATE/DELETE, QoS **TRANSIENT_LOCAL+RELIABLE**)
  et `/<world>/renderer_poses` (`VesselPositionArray`, chaque tick). ⚠️ Côté Unity,
  `LotusimInterface.m_namespace` **doit** = le nom du world (piège « connecté, rien ne
  s'affiche » : défaut `Silent_Storm`).
- **Le mesh ne circule PAS** sur le fil : le flux porte un *nom* + des poses. Unity résout
  le mesh via **Addressables** : `Addressables.LoadAssetAsync<GameObject>(renderer_obj_name)`.
  → côté Unity : un prefab dont l'**adresse Addressable == `renderer_type_name`**.
- **CREATE latché** : gz publie le CREATE en TRANSIENT_LOCAL au spawn ; si Unity souscrit
  après, re-tirer le CREATE (restart gz, ou pub manuel **avec**
  `--qos-durability transient_local --qos-reliability reliable`).
- **Conversion de repère, côté Unity** (`Assets/Scripts/lotusim_interface/common.cs`,
  `CoordinateSystemUtils.GzPoseToUnityPose`) : Unity est **gaucher, Y-up**.
  position `(x, z, y)` ; rotation `(-x, -z, -y, w)` — c'est le **`Z→-Y`** documenté. Transform
  **fixe et générique**, appliquée à toute pose gz reçue (indépendante de xdyn).

## 4. Mur HDRP sous WSLg (si tu lances le frontend Unity dans WSL2)

Le **rendu OpenGL** de gz tombe sur `llvmpipe` (soft) par défaut → forcer
`GALLIUM_DRIVER=d3d12` (4090 via D3D12) pour la **GUI gz**. MAIS le **frontend Unity rend en
VULKAN** (HDRP, Linux) et **WSLg n'expose aucun device Vulkan GPU** : seul ICD présent =
**lavapipe** (Vulkan CPU, `deviceType=4`), **qu'Unity REFUSE** (`Could not select a physical
device`) → fallback OpenGL → HDRP : *« OpenGLCore is not supported with HDRP »*. Même
`-force-vulkan` n'aide pas. Ubuntu 24.04 Mesa ne livre pas **Dozen (`dzn`)** en amd64, et le
driver NVIDIA WSL n'expose que des DLL Windows. → **Unity HDRP dans WSL = nécessite Dozen**
(Vulkan-sur-D3D12, PPA Mesa) ; sinon utiliser Unity **sur Windows**. (gz GUI, elle, marche.)

## 5. Gotcha mesh pour l'import Unity

Le mesh visual d'un modèle peut être `.dae`/`.stl`/`.obj` pour gz, mais **l'export COLLADA
`.dae` de Blender 4.5 est cassé pour l'import Unity** (produit `<instance_geometry>` vide →
import vide). Pour Unity : exporter en **FBX** via `blender --background … --python` avec
`bake_space_transform=True, axis_forward='-Z', axis_up='Y'` (Z-up Blender → Y-up Unity baké
dans les sommets, racine à l'identité — critique car le flux de poses écrase la rotation racine).

## 6. macOS : conteneur émulé (Rosetta) + Unity natif (Metal)

Sur Apple Silicon, le mur HDRP/Vulkan de WSL (§4) disparaît : Unity rend en **Metal**,
nativement. Approche validée : tout le ROS/gz/xdyn dans un **conteneur Docker amd64 sous
Rosetta** (headless, sans GPU), Unity **natif** comme client de rendu, reliés par
`ros_tcp_endpoint` (ROS2) ou TCPUDP. Pièges (génériques à tout pont LOTUSim-Unity sur Mac) :

- **amd64 sous Rosetta, pas arm64 natif** : les binaires xdyn livrés dans `physics/` sont des
  ELF **x86-64** (pas de source dans le core → rebuild arm64 = `LOTUSim-Xdyn`, lourde).
  Builder l'image `--platform linux/amd64` ; Rosetta tient une co-sim mono-bateau.
- **DDS intra-conteneur : garder le SHM.** Un Dockerfile qui pose
  `FASTDDS_BUILTIN_TRANSPORTS=UDPv4` **désactive la mémoire-partagée** → un abonné créé *avant*
  son publisher (cas du pont : l'endpoint souscrit avant que gz publie) ne matche jamais en
  multicast-loopback → 0 message livré (`topic info` Publisher count: 0 alors que `topic hz`
  reçoit = symptôme). → forcer **`FASTDDS_BUILTIN_TRANSPORTS=DEFAULT`**.
- **`ros_tcp_endpoint` est mono-thread (Python).** Sous la charge gz (poses + découverte DDS)
  + l'overhead Rosetta, le GIL **affame la boucle `accept()`** → le client Unity ne peut plus
  se connecter (endpoint *seul* sans gz = accept OK ; avec gz = KO → test de localisation).
  Pattern **connect-first** : laisser l'endpoint *idle* accepter Unity AVANT de démarrer gz
  (une connexion déjà établie n'est pas affectée par la famine).
- ⭐ **La scène applicative peut détruire le récepteur de rendu.** Le projet Unity LOTUSim a un
  flow Photon : son `GameManager` recharge la scène `Launcher`
  (`if (!PhotonNetwork.IsConnected) LoadScene(...)`) quand on joue une scène **standalone** sans
  Photon connecté → **détruit le `LotusimConnector`** (qui instancie les prefabs sur CREATE) →
  rien ne s'affiche, et **ça se déguise en bug de pont/relaye** (le `RosInterface` singleton
  survit au reload et masque le problème ; le connector, non). → bypasser la redirection, ou
  Photon en OfflineMode, ou partir d'une **scène minimale dédiée** (mer + connector + caméra,
  sans Photon).
- **Socket TCP zombie côté Unity.** La `ROSConnection` persiste à travers Stop/Play (singleton)
  → après un restart du conteneur, un socket `CLOSE_WAIT` côté Unity coince le proxy Docker
  Desktop sur le port. Quitter+rouvrir l'Éditeur libère le socket ; éviter les restarts de
  conteneur pendant qu'Unity est connecté.
- **colcon sur image prébuildée** : reprendre le layout de l'image (`--merge-install` si elle a
  été buildée ainsi), sinon « install dir created with merged layout ».

Bug upstream corrigé en route : **double-`Start`** dans `LotusimConnector.cs` (interface
démarrée 2× — par la factory avec un namespace vide, puis par le connector → churn de socket).
TCPUDP (`<connection_protocol>TCPUDP</connection_protocol>`) = alternative directe gz→Unity
sans endpoint ni DDS : **gz client**, **Unity serveur** (port unique TCP+UDP), `<ip>` = **IPv4
numérique** de l'hôte vu du conteneur (`host.docker.internal`, pas un hostname car `from_string`).
