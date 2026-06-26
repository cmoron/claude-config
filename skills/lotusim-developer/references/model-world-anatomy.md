# Anatomie d'un modèle et d'un world

> **Périmètre** : ce fichier couvre le **modèle** (assets, dans le **core**) et le **world**.
> Le **comportement/contrôleur** d'un vaisseau ne vit **pas** ici — il va dans
> **`LOTUSim-generic-scenario`** (`src/agents/`), cf. `ecosystem-and-architecture.md`.

## Modèle : `assets/models/<name>/`

```
<name>/
├── model.config     # métadonnées Gazebo, pointe vers model.sdf
├── model.sdf        # SDF 1.10 : links, collision, capteurs (souvent PAS de visual)
├── <name>.yaml      # modèle xdyn : TOUTE la dynamique (inertie, added-mass, propulsion)
└── meshes/          # .dae (rendu) + .stl (hydrostatique xdyn)
```

### model.config

```xml
<?xml version="1.0"?>
<model>
  <name>BlueBoat</name>
  <version>1.0</version>
  <sdf version="1.7">model.sdf</sdf>
  <author><name>...</name></author>
  <maintainer>...</maintainer>
  <description>...</description>
</model>
```

### model.sdf (minimal — c'est volontaire)

Le `model.sdf` est **petit** : un `base_link` avec une géométrie de **collision** et
des capteurs custom. **Aucun plugin de physique ici** (la dynamique vient de xdyn),
souvent **aucun `<visual>` ni inertiel**. Capteur AIS typique : `gz:type="ais"`.

```xml
<?xml version="1.0"?>
<sdf version="1.10">
  <model name="blueboat">
    <link name="base_link">
      <collision name="base_collision">
        <geometry><mesh><uri>model://blueboat/meshes/blueboat.stl</uri></mesh></geometry>
      </collision>
      <!-- AJOUTER pour le voir dans la GUI Gazebo (cf. fremm/commando) : -->
      <visual name="visual">
        <geometry><mesh><uri>model://blueboat/meshes/blueboat.dae</uri></mesh></geometry>
      </visual>
      <sensor name="ais" type="custom" gz:type="ais">
        <update_rate>1</update_rate>
        <noise_sigma>0.01</noise_sigma>
        <noise_amplitude>0.01</noise_amplitude>
      </sensor>
    </link>
  </model>
</sdf>
```

### Visual vs Unity (important)

| Rendu dans | Modèles | `<visual>` dans model.sdf |
|---|---|---|
| **Unity** (`render_plugin`→ROS2→prefab) | wamv, dtmb_hull, lrauv, mine, pha, bluerov2 | non (collision seule) |
| **Gazebo** (direct) | fremm, commando, landscape, x500 | oui |

Conséquence : un modèle "collision seule" est **invisible dans la GUI gz** (toggle
*Entity Tree → clic droit → View → Collisions* pour le voir). Donner un Unity au
véhicule = créer un **prefab HDRP** dans `LOTUSim-Unity-modules` + mapping nom→prefab
(`LotusimBaseInterface.cs`, *"Maps vessel names to prefab names"*) — pipeline d'art
séparé, lourd. Pour une démo/contrib autoportante : donner un `<visual>` gz (pattern
légitime, cf. fremm/commando).

⚠️ Un `<visual>` ne suffit pas à le VOIR dans la GUI gz : les worlds LOTUSim
n'embarquent pas le `SceneBroadcaster` (ils rendent dans Unity). Ajouter au world
`<plugin filename="gz-sim-scene-broadcaster-system" name="gz::sim::systems::SceneBroadcaster"/>`
pour rendre le `<visual>` dans gz (et publier les topics de pose, cf. l'oracle).

⚠️ **Orientation — convention LOTUSim : l'avant du mesh est sur +y** (mesuré sur
`fremm.dae` : 142 m en y, 24 m en x). Un mesh étrave-sur-+x s'affiche **de travers**
("en crabe", 90° par rapport au cap). Fix : modéliser l'avant sur +y, ou poser un
`<pose>0 0 0 0 0 1.5708</pose>` sur le `<visual>`. La physique (STL/xdyn) n'est pas
affectée — c'est purement le rendu.

### `<name>.yaml` — le modèle xdyn (la dynamique)

C'est ici que vit la physique. Structure (cf. `wamv.yaml`, `dtmb-xdyn.yml`,
`lrauv.yml`) :

```yaml
rotations convention: [psi, theta', phi'']
environmental constants:
    g:   {value: 9.81, unit: m/s^2}
    rho: {value: 1025, unit: kg/m^3}        # eau de mer
    nu:  {value: 1.18e-6, unit: m^2/s}
environment models:
    - model: no wind
    - model: no waves
      constant sea elevation in NED frame: {value: 0, unit: m}
    - model: ekman current        # ou 'no current'
      ...
bodies:
  - name: BLUEBOAT
    mesh: blueboat/meshes/blueboat.stl       # pour hydrostatique + Froude-Krylov
    position of body frame relative to mesh: { frame: mesh, x/y/z/phi/theta/psi }
    initial position of body frame relative to NED: { frame: NED, ... }
    initial velocity of body frame relative to NED: { frame: BLUEBOAT, u/v/w/p/q/r }
    dynamics:
        hydrodynamic forces calculation point in body frame: { x,y,z }
        centre of inertia: { frame: BLUEBOAT, x,y,z }
        rigid body inertia matrix at the center of gravity and projected in the body frame:
            row 1..6: [ ... 6x6 ... ]
        added mass matrix at the center of gravity and projected in the body frame:
            row 1..6: [ ... 6x6 ... ]
        # + damping, et la PROPULSION (thrusters nommés — voir ci-dessous)
```

La **propulsion** définit des actionneurs **nommés** (ex. `PSPropRudd`, `SBPropRudd`
sur dtmb pour un layout twin) — ces noms doivent matcher `<thrusters>` du world.
S'inspirer de `lrauv` (propeller wageningen B-series) et `dtmb_hull` (twin). Clés
xdyn dépréciées tolérées (warnings "center of buoyancy" → préférer "center of
gravity").

### Générer les meshes avec Blender + blender-mcp

Deux meshes par modèle : **`<name>.dae`** (visual COLLADA, si on donne un `<visual>`
au modèle) et **`<name>.stl`** (coque *fermée* pour l'hydrostatique xdyn, référencée
par `<name>.yaml`). Un agent peut les produire/nettoyer en pilotant Blender via
**blender-mcp** (addon socket dans Blender + serveur MCP `blender` côté Claude Code).

- **Blender 4.5 LTS, pas 5.0** : l'exporteur **COLLADA `.dae`** existe en 4.5 (retiré
  en 5.0). Tarball officiel autoportant ; `requests` est déjà dans le Python embarqué
  de Blender 4.5, donc l'addon s'enregistre sans pip.
- **STL : normales vers l'extérieur.** xdyn avertit `N facets seem oriented inwards`
  si les normales sont incohérentes (une édition de vertices peut les retourner) →
  fausse l'hydrostatique. En Blender : Edit Mode → `normals_make_consistent(inside=False)`
  avant l'export STL.
- **Splash Blender** : sous MCP, la 1ʳᵉ capture viewport renvoie l'écran d'accueil →
  `bpy.context.preferences.view.show_splash=False` + `save_userpref()`.
- **Setup** : copier `addon.py` dans `~/.config/blender/<ver>/scripts/addons/`,
  l'activer + `save_userpref` ; côté client
  `claude mcp add blender --scope user -- <chemin-uvx> blender-mcp`. ⚠️ Les *tools* MCP
  n'apparaissent qu'**après redémarrage** de Claude Code (chargés au démarrage).
- **Gotcha WSL2/WSLg (coûte des heures)** : Blender ouvert **maximisé** plante —
  `GHOST/Wayland: xdg_wm_base error 4: xdg_surface buffer (WxH) does not match the
  configured maximized state` (mismatch de ~48 px = barre de titre). La main-loop GUI
  meurt → les `bpy.app.timers` ne sont plus pompés → le serveur écoute sur 9876 mais
  **ne répond jamais** (recv timeout / connection reset). Parade : fenêtre
  **non-maximisée** via `-p <x> <y> <w> <h>`. Le serveur refuse aussi `-b` (headless) :
  il faut une GUI (ou `xvfb-run`). Forcer le GPU `GALLIUM_DRIVER=d3d12` (sinon llvmpipe,
  rendu software).

  ```bash
  # lancement STABLE sous WSLg (fenêtre fixe + GPU + démarrage du serveur MCP)
  DISPLAY=:0 GALLIUM_DRIVER=d3d12 MESA_LOADER_DRIVER_OVERRIDE=d3d12 \
    blender -p 100 100 1600 900 --python start_server_gui.py
  #   start_server_gui.py : addon_enable('addon') ; scene.blendermcp_port = 9876 ;
  #                         bpy.ops.blendermcp.start_server()
  ```

  Smoke test indépendant du MCP : socket brut sur `127.0.0.1:9876`, envoyer
  `{"type":"get_scene_info"}`, attendre `{"status":"success", ...}`.

## World : `assets/worlds/*.world`

Plugins **au niveau world** (une fois), puis chaque véhicule en `<include>`.

```xml
<sdf version="1.7">
  <world name="lotusim">
    <gravity>0 0 0</gravity>          <!-- xdyn fait TOUTES les forces, pas gz -->
    <plugin filename="physics_interface_plugin" name="lotusim::gazebo::PhysicsInterfacePlugin"/>
    <plugin filename="entity_manager_plugin"   name="lotusim::gazebo::EntityManager"/>
    <plugin filename="lotusim_sensor_plugin"   name="lotusim::sensor::LotusimSensorPlugin"/>
    <plugin filename="render_plugin"           name="lotusim::gazebo::RenderPlugin">
        <connection_protocol>ROS2</connection_protocol>
    </plugin>
    <plugin filename="waypoint_plugin"         name="lotusim::gazebo::WaypointFollowerPlugin"/>

    <include>
      <uri>model://blueboat</uri>
      <name>blueboat1</name>
      <pose>0 0 0 0 0 0</pose>
      <lotus_param>
        <physics_engine_interface>            <!-- wire le vaisseau à un serveur xdyn -->
          <surface>
            <connection_type>XDynWebSocket</connection_type>
            <uri>ws://127.0.0.1:12345</uri>   <!-- un port unique par vaisseau -->
            <thrusters>
              <thruster1>PSPropRudd</thruster1>   <!-- noms = ceux du yaml xdyn -->
              <thruster2>SBPropRudd</thruster2>
            </thrusters>
          </surface>
          <init_state>Surface</init_state>
        </physics_engine_interface>
        <waypoint_follower>                   <!-- navigation CINÉMATIQUE, PAS une poussée xdyn (cf. piège n°6) -->
          <follower>
            <loop>true</loop>
            <linear_velocities_limits>0.1 10</linear_velocities_limits>
            <linear_pid>0.3 0.05 0.1</linear_pid>
            <angular_pid>0.8 0.05 0.4</angular_pid>
            <range_tolerance>2.0</range_tolerance>
            <circle><radius>20</radius></circle>
          </follower>
        </waypoint_follower>
        <render_interface>
          <publish_render>true</publish_render>
          <renderer_type_name>wamv</renderer_type_name>   <!-- clé prefab Unity -->
        </render_interface>
      </lotus_param>
    </include>
  </world>
</sdf>
```

Worlds de référence : `circling_ship_example.world` (1 vaisseau cinématique, sans
`physics_engine_interface`), `xdyn_multithread_test.world` (2 vaisseaux avec xdyn sur
12345/12346). Le modèle par défaut chargé par `entity_manager` est `model.sdf`
(surchargeable via `sdf_file`).
