# Project Memory — Neon Ronin

## Task 1: Cyberpunk City Arena

### Architecture
- Level scene root is `Node3D` named "Level"
- All geometry (buildings, ground, cover) is inside `NavigationRegion3D` so navmesh baking covers it
- Buildings are CSG boxes with `building_facade.png` texture, UV-tiled per building size
- Street layout: main corridor runs north-south (Z axis), width ~8m between building facades at x=+/-4
- East/west alleys at x=+/-14 between main row and back row of buildings
- Small buildings at center create junction points

### Node Hierarchy
- `Level/NavigationRegion3D/Ground` — CSGBox3D, 64x64m, collision enabled
- `Level/NavigationRegion3D/Buildings/Building_N` — CSG buildings with collision
- `Level/NavigationRegion3D/Cover/` — vending machines, dumpsters, crates, barriers
- `Level/Lights/StreetSpot_N` — colored spot lights angled down at streets
- `Level/SpawnPoints/Spawn_N` — 8 Marker3D nodes, positions at y=1
- `Level/PickupSpots/Pickup_N` — 6 Marker3D nodes
- `Level/WorldEnvironment` — ACES tonemap, glow, volumetric fog, SSR, SSAO
- `Level/Moonlight` — dim DirectionalLight3D

### Spawn Point Positions
- Spawn_0: (0, 1, 0), Spawn_1: (14, 1, -10), Spawn_2: (-14, 1, 10)
- Spawn_3: (0, 1, -20), Spawn_4: (0, 1, 20), Spawn_5: (14, 1, 10)
- Spawn_6: (-14, 1, -10), Spawn_7: (0, 1, -10)

### Pickup Spot Positions
- Pickup_0: (0, 0.5, -5), Pickup_1: (14, 0.5, 0), Pickup_2: (-14, 0.5, 0)
- Pickup_3: (0, 0.5, 15), Pickup_4: (2, 0.5, -15), Pickup_5: (-2, 0.5, 10)

### Lighting Setup
- Very dark ambient (Color 0.02, 0.02, 0.05, energy 0.3)
- Moonlight energy 0.15, pale blue
- Neon signs use SHADING_MODE_UNSHADED + emission_texture for visible text
- OmniLight3D per sign casts colored light onto surroundings (range 6-10m)
- SpotLight3D angled at streets (range 15m)
- Window strips on buildings add warm yellow, cool blue, purple ambient

### Known Issues
- CSG buildings are untextured-looking in dark lighting — building_facade.png IS applied but subtle
- Neon sign textures show as colored rectangles at distance — the Japanese text detail is only visible close-up
- NavigationMesh needs runtime baking — the nav_mesh is assigned but not baked in the scene builder (use `nav_region.bake_navigation_mesh()` at runtime or via editor)
- Volumetric fog is subtle — density 0.02, increase if more atmosphere needed

### Technical Notes
- GPU rendering available at DISPLAY=:0 (AMD Radeon 890M) — use `DISPLAY=:0 godot --rendering-method forward_plus`
- No xvfb-run available — use DISPLAY=:0 directly
- CSGBox3D.material sets material on all faces — cannot do per-face materials
- Headless mode cannot load textures (--script), but textures load fine at runtime with GPU
- RID leak warnings on headless exit are harmless (per quirks.md)

## Task 2: Player Controller, Weapons & Combat

### Architecture
- Player scene root is `CharacterBody3D` named "Player" with `player_controller.gd`
- Head pivot at y=1.6 contains Camera3D
- WeaponHolder at Camera3D/WeaponHolder with `weapon_manager.gd`
- WeaponRaycast at Camera3D/WeaponRaycast (target_position z=-200)
- Player collision layer=1 (player), mask=4|8 (environment+pickups)
- HUD is CanvasLayer with `hud_controller.gd`, anchored UI elements

### Node Hierarchy
- `Player/CollisionShape3D` — CapsuleShape3D r=0.3 h=1.8, position y=0.9
- `Player/Head` — Node3D at y=1.6 (camera pivot for mouse look)
- `Player/Head/Camera3D` — FOV 75, current=true
- `Player/Head/Camera3D/WeaponHolder` — Node3D with weapon_manager.gd, pos (0.25, -0.15, -0.4)
- `Player/Head/Camera3D/WeaponRaycast` — RayCast3D for weapon hits

### Weapons
- Handgun: 25 dmg, semi-auto, 12-round mag, 36 reserve, 0.3s fire rate
- Rifle: 18 dmg, full-auto, 30-round mag, 90 reserve, 0.1s fire rate, spread buildup
- Shotgun: 15 dmg/pellet, 8 rays cone, 6-shell mag, 24 reserve, 0.8s fire rate
- Weapon models loaded from GLB at runtime by weapon_manager.gd, scaled to target size
- Muzzle flash via OmniLight3D toggled on fire, 0.05s duration

### HUD Layout
- HealthBar: ProgressBar, anchored bottom-left with green fill StyleBoxFlat
- AmmoLabel: Label, anchored bottom-right, font size 22
- WeaponLabel: Label, anchored bottom-right above ammo, cyan color, font size 14
- Crosshair: "+" Label, anchored center, font size 24
- KillFeed: VBoxContainer, anchored top-right, max 4 entries with 3s fadeout
- Scoreboard: PanelContainer, anchored center, dark semi-transparent, toggled by Tab key

### Pickups
- PickupHealth: Area3D with health_pickup.glb, green OmniLight3D glow, heals +50 HP
- PickupAmmo: Area3D with ammo_crate.glb, orange OmniLight3D glow, refills current weapon ammo
- Both use pickup.gd with body_entered detection on layers 1|2
- 15s respawn timer after collection, collision shape disabled during respawn
- 6 pickups placed in main.tscn at the PickupSpot positions from Task 1

### Movement
- Walk 5 m/s, Sprint 8 m/s (hold Shift), lerp-based acceleration
- Crouch-slide: triggered by crouch while sprinting, 12 m/s initial burst, decelerates 8 m/s^2
- Camera height lowers from 1.6 to 0.8 during slide, lerped at 10x delta
- Mantle: when pressing forward into wall + no obstacle at head height, velocity boost up+forward

### Technical Notes
- GameManager autoload handles spawn points, kill registration, score tracking
- Signal connections made via call_deferred("_connect_signals") in HUD to avoid ready-order issues
- GameManager accessed via root.get_children() loop matching by name (autoload pattern)
- Weapon models hidden/shown on switch, fire cooldown prevents spam
- Impact sparks use GPUParticles3D with ParticleProcessMaterial, auto-cleanup after 0.5s
- VQA issues about level geometry (primitive buildings, missing textures) are Task 1 concerns, not Task 2
