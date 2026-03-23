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

## Task 2 Refactor: Multi-Level GameManager

### Changes
- Removed hardcoded `spawn_points` and `pickup_spots` arrays from `_ready()`
- Added `load_level_data(level_root)` that walks scene tree for SpawnPoints/PickupSpots Marker3D children
- Auto-detection via `_process()` polling: scans for "Level" node in scene tree each frame until found, then stops
- Added multi-level state: `current_level`, `level_order` array, `score_limit=20`, `match_active=true`, `level_names` dict
- Added `match_ended(winner_name)` signal, emitted when any player reaches `score_limit` kills
- Added `advance_to_next_level()` (increments `current_level`, wraps around, resets `_level_loaded` flag)
- Added `reset_match()` (resets all scores to 0, re-enables match)
- Navmesh baking now triggered after level data loads (not in `_ready()`)
- `_bake_navmesh()` retained and called internally after `load_level_data()`

### Compatibility
- All existing public API preserved: `register_entity`, `register_kill`, `get_safest_spawn_point`, `get_random_spawn_point`, `get_scores`, `get_entity`
- `spawn_points` and `pickup_spots` remain public vars (bot_controller.gd accesses `spawn_points` directly for patrol waypoints)
- `kill_registered` and `score_updated` signals unchanged
- Fallback to `Vector3(0, 1, 0)` when `spawn_points` is empty (before level loads)

### Technical Notes
- `_process()` polling approach chosen because: autoload `_ready()` fires before main scene loads, `tree_changed` signal was unreliable for deferred detection, and `process_frame` one-shot doesn't survive scene transitions
- `_level_loaded` flag prevents redundant tree scanning after level is found
- `advance_to_next_level()` resets `_level_loaded` so `_process` will re-scan for new level

## Task 4: Presentation Video

### Architecture
- SceneTree script at test/presentation.gd, extends SceneTree
- Loads main.tscn, creates separate CinematicCamera, disables player camera every frame
- 900 frames at 30 FPS = 30 seconds of video
- 10 shots across 3 acts: establishing (9s), combat showcase (12s), finale (9s)

### Camera Choreography
- Act 1: High crane descent → orbit at medium height → low street-level dolly
- Act 2: Third-person bot tracking → two-bot action shot → close shoulder cam → sweeping overhead
- Act 3: Orbiting most-active bot → ground-level pullback → final wide crane up
- Smoothstep easing on fixed-path shots, lerp on tracking shots

### Technical Notes
- GPU rendering at DISPLAY=:0 with AMD Radeon 890M, `--rendering-method forward_plus`
- `DISPLAY=:0` must be set as environment variable before `timeout`, not after
- AVI output from `--write-movie`, converted to H.264 MP4 via ffmpeg (CRF 28, ~2.5MB)
- Player camera must be disabled EVERY frame (chase camera re-assertion quirk)
- Camera pre-positioned in `_initialize()` for frame 0 (--write-movie renders before _process)
- Manual look-at via atan2/asin to avoid `look_at()` issues during initialization
- Bot kill feed is visible in the video, confirming combat AI is active during recording

## Task 3: Dynamic Level Loading

### Architecture
- `main_controller.gd` attached to Main root (Node3D), handles all dynamic spawning
- Level scene loaded from `GameManager.get_current_level_path()`, instanced as "Level" child
- Bots and pickups spawned at runtime based on level Marker3D positions
- Player, HUD, PauseMenu, DevConsole remain static in build_main.gd scene builder

### Node Hierarchy (at runtime)
- `Main` (Node3D + main_controller.gd)
  - `Player` (CharacterBody3D + player_controller.gd) — static, repositioned at runtime
  - `HUD` (CanvasLayer + hud_controller.gd) — static
  - `PauseMenu` (CanvasLayer + pause_menu.gd) — static
  - `DevConsole` (CanvasLayer + dev_console.gd) — static
  - `Level` (Node3D) — dynamically loaded from GameManager.level_order
  - `Bot_Alpha..Delta` (CharacterBody3D + bot_controller.gd) — dynamically spawned
  - `PickupHealth_N` / `PickupAmmo_N` (Area3D + pickup.gd) — dynamically spawned

### Spawning Flow
1. `_ready()`: Load level scene, instance as "Level" child
2. `_on_level_added()` (deferred): Call `GameManager.load_level_data()` with level instance
3. `_spawn_entities()` (deferred): Reposition player, spawn 4 bots, spawn pickups alternating health/ammo
4. Bots get `bot_controller.gd` via `set_script()` at spawn time
5. Pickups get `pickup.gd` via `set_script()` at spawn time with type set via `set("pickup_type", ...)`

### Match End
- `match_ended` signal from GameManager pauses tree
- Inline CanvasLayer overlay shows winner, final scores, escape hint
- No separate match_end_screen.tscn needed

### Technical Notes
- `call_deferred` chain ensures global positions are valid before reading Marker3D positions
- Bot collision: layer=2, mask=1|2|4 (set in bot_controller._ready() AND at spawn time)
- Pickup collision: layer=0, mask=1|2 (set in pickup._ready())
- HUD connects to Player via `get_parent().get_node_or_null("Player")` — Player must stay a direct child of Main
- GameManager's `_process()` auto-detection still works as fallback (finds "Level" node in tree)

## Task 4: Skyscraper Rooftop Level

### Architecture
- Level scene root is `Node3D` named "Level" with `level_skyscraper_materials.gd` attached
- Two rooftops (A at X=-20, B at X=25) connected by a sky bridge, all at Y=40
- Each rooftop has a door structure leading to stairs (16 steps, 0.25m rise each) descending from Y=40 to Y=36
- Kill zone Area3D at Y=10 kills any entity that falls off the buildings

### Node Hierarchy
- `Level/WorldEnvironment` — sunset sky, ACES tonemap, warm fog, glow, SSAO
- `Level/Sunlight` — warm orange DirectionalLight3D angled from the west
- `Level/NavigationRegion3D/RooftopA/` — platform, parapets (east has gap for bridge), 5 AC units (GLB), door structure, 6 crates (CrateA_0..5, some stacked)
- `Level/NavigationRegion3D/RooftopB/` — platform, parapets (west has gap), helipad (CSGCylinder3D), walkways, railings, door structure, 6 crates (CrateB_0..5, some stacked)
- `Level/NavigationRegion3D/SkyBridge/` — bridge floor, glass side walls (semi-transparent), 3 cover pillars
- `Level/NavigationRegion3D/OfficeA/` — 20x15m floor plate at Y=36, ceiling, outer walls, 2 partition walls with doorways, furniture (desks/chairs/monitors GLB), 6 SpotLight3D, 2 water coolers + 2 plants in corners
- `Level/NavigationRegion3D/OfficeB/` — 15x12m floor plate at Y=36, 2 rooms, furniture, 4 SpotLight3D, 2 water coolers + 2 plants in corners
- `Level/NavigationRegion3D/StairsA`, `StairsB` — 16-step staircases (CSGBox3D steps) connecting rooftops to offices, replacing former ramps
- `Level/Facades/FacadeA`, `FacadeB` — tall CSGBox3D columns below rooftops with glass_window texture
- `Level/KillZone` — Area3D at Y=10, 200x200m, kill_zone.gd kills entities on contact
- `Level/SpawnPoints/Spawn_0..7` — 8 Marker3D at Y=41 (rooftops, bridge, office)
- `Level/PickupSpots/Pickup_0..7` — 8 Marker3D at Y=40.5 or Y=37 (2 added on sky bridge)

### Spawn Point Positions
- Spawn_0: (-25, 41, -10), Spawn_1: (-15, 41, 8), Spawn_2: (-28, 41, 12)
- Spawn_3: (30, 41, -5), Spawn_4: (20, 41, 5), Spawn_5: (18, 41, -10)
- Spawn_6: (3.75, 41, 0), Spawn_7: (-18, 37, 5)

### Pickup Spot Positions
- Pickup_0: (-25, 40.5, 0), Pickup_1: (-30, 40.5, -10), Pickup_2: (30, 40.5, 5)
- Pickup_6: (-2, 40.5, 0) [sky bridge west], Pickup_7: (9, 40.5, 0) [sky bridge east]
- Pickup_3: (15, 40.5, -8), Pickup_4: (3.75, 40.5, 0), Pickup_5: (22, 37, 3)

### Technical Notes
- Fog enabled via `env.fog_enabled` and `env.fog_density` (not volumetric fog for this level)
- Glass bridge walls use `TRANSPARENCY_ALPHA` with Color(0.3, 0.5, 0.8, 0.4)
- Partition walls implemented as two CSGBox3D segments with 2m doorway gap
- AC units, desks, chairs, monitors all instantiated from GLB files
- kill_zone.gd connects body_entered signal, calls take_damage(9999) or sets health=0
- GameManager already has level_skyscraper.tscn in level_order array (added in Task 3)

## Task 8: Visual QA — Skyscraper Level

### Issues Found and Fixed
- **Broken textures**: All 7 skyscraper-specific textures (concrete_rooftop, glass_window, office_floor, office_wall, helipad_marking, metal_railing, sunset_sky) were JPEG files saved with `.png` extensions. Godot's PNG loader rejected them with "Not a PNG file" errors. Fixed by converting all to actual PNG format via ImageMagick.
- **Skybox invisible**: Fog at density 0.005 with no `fog_sky_affect` setting washed out the panorama skybox entirely. Fixed by reducing fog_density to 0.003 and setting fog_sky_affect to 0.15.
- **Skybox seam**: sunset_sky.png was 2752x1536 (not proper 2:1 equirectangular ratio). Resized to 3072x1536 and blended the wrap-around edges.
- **Harsh shadows**: DirectionalLight3D shadow_blur increased from 2.0 to 5.0, ambient_light_energy increased from 0.5 to 0.7.
- **Glass facade tiling**: Reduced glass_mat UV scale from (8,10,1) to (4,5,1) to reduce obvious texture repetition.

### Remaining VQA Notes (not fixable without architectural changes)
- AC units from GLB render dark in sunset backlighting — correct behavior, they ARE textured 3D models
- Building bases are visible at overview zoom — intentional rooftop level design, buildings float above kill zone
- Office interiors are large rooms with scattered furniture clusters — 10 desks, 10 chairs, 10 monitors across 5 clusters
- reference.png is for the cyberpunk night city (level 1), NOT the skyscraper sunset level — VQA "thematic mismatch" is expected

### Technical Notes
- JPEG-as-PNG is a common issue from AI image generation services (Gemini) — always verify with `file` command
- `fog_sky_affect` controls how much fog obscures the skybox panorama (0=none, 1=full) — essential for outdoor scenes
- Equirectangular panoramas must be exactly 2:1 aspect ratio to wrap seamlessly
- `--script` mode AND scene-mode both fail to load textures when .import files have `valid=false` — must delete broken .import files and reimport
- Scene-based test (`.tscn` + attached `.gd`) works the same as `--script` for texture loading — the issue is the import cache, not the launch mode

## Ceiling Stairwell Gap Fix

### Problem
- CSGCombiner3D with CSGBox3D OPERATION_SUBTRACTION creates a visual hole in the ceiling but the collision mesh remains solid — player cannot pass through
- CSG boolean subtraction does not update the collision shape to match the visual subtraction

### Solution
- Replaced CSGCombiner3D ceilings with split CSGBox3D segments arranged around the stairwell opening, leaving a physical gap
- Same pattern as parapet walls (ParapetA_East_N/S with gap for bridge)
- Each segment is a standalone CSGBox3D with use_collision=true, collision_layer=4, collision_mask=0, material=office_wall_mat
- Segments are direct children of office_a/office_b (NOT inside a CSGCombiner3D)

### Lesson Learned
- CSG boolean subtraction in Godot does NOT reliably cut collision meshes — only visual geometry
- For passable openings, always use split geometry with physical gaps instead of boolean subtraction
