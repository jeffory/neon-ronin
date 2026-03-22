# Game Plan: Neon Ronin

## Game Description

A 3D first-person shooter with cyberpunk aesthetics. Dark Tokyo-inspired city level with colorful neon illumination. Free-for-all deathmatch with 4 bots. Three weapons: handgun, rifle, shotgun. Modern polished movement with sprint, crouch-slide, and mantle. Health, ammo, and pickup systems.

## 1. Cyberpunk City Arena
- **Status:** pending
- **Depends on:** (none)
- **Targets:** scenes/level.tscn, scenes/build_level.gd
- **Goal:** Build the playable arena — the neon-lit Tokyo cityscape that defines the game's visual identity and provides the spatial layout for all combat.
- **Requirements:**
  - Enclosed arena (~60m x 60m) of narrow streets, alleyways, and open plazas using CSG and MeshInstance3D geometry
  - Tall building facades line the streets with varied heights and setbacks
  - Colorful neon lighting throughout — OmniLight3D and SpotLight3D in vivid pink, cyan, purple, orange casting onto wet-look reflective street surfaces
  - Emissive material signs and panels on buildings for neon glow effect
  - WorldEnvironment with glow/bloom, volumetric fog, dark ambient, ACES tonemap
  - Cover objects: vending machines, dumpsters, crates, barriers at combat-appropriate heights (~1m for mantling)
  - 6+ spawn points distributed across the arena, marked with Marker3D nodes
  - 4+ pickup locations marked with Marker3D nodes
  - NavigationRegion3D with baked NavigationMesh covering all walkable surfaces
  - DirectionalLight3D as dim moonlight for baseline visibility
- **Assets:**
  - `neon_sign_1` texture (`assets/img/neon_sign_1.png`) — 1m x 0.5m emissive sign panels
  - `neon_sign_2` texture (`assets/img/neon_sign_2.png`) — 1m x 0.5m emissive sign panels
  - `neon_sign_3` texture (`assets/img/neon_sign_3.png`) — 1m x 0.5m emissive sign panels
  - `building_facade` texture (`assets/img/building_facade.png`) — tile every 4m via UV scale
  - `street` texture (`assets/img/street.png`) — tile every 4m via UV scale
  - `night_sky` background (`assets/img/night_sky.png`) — skybox panorama
- **Verify:** First-person camera shows a dark city environment densely lit by colorful neon signs. Streets are navigable, cover objects are placed at natural positions, and the overall mood matches the reference image — dark with vivid neon color splashes.

## 2. Player Controller, Weapons & Combat
- **Status:** pending
- **Depends on:** 1
- **Targets:** scenes/player.tscn, scenes/build_player.gd, scenes/hud.tscn, scenes/build_hud.gd, scenes/pickup_health.tscn, scenes/build_pickup_health.gd, scenes/pickup_ammo.tscn, scenes/build_pickup_ammo.gd, scenes/main.tscn, scenes/build_main.gd, scripts/player_controller.gd, scripts/weapon_manager.gd, scripts/hud_controller.gd, scripts/pickup.gd, scripts/game_manager.gd
- **Goal:** Implement the complete player experience — fluid modern FPS movement, three distinct weapons, health/damage, pickups, and HUD. This is the core gameplay loop.
- **Requirements:**
  - CharacterBody3D FPS controller with camera at head height, mouse look
  - Movement: walk (5 m/s), sprint (8 m/s, hold Shift), crouch-slide (triggered by crouch while sprinting, momentum burst then deceleration, lower camera), mantle (auto-vault when pressing forward into geometry ~0.5-1.2m tall)
  - Three weapons with distinct feel:
    - Handgun: semi-auto (click per shot), 12-round mag, moderate damage, fast swap speed
    - Rifle: full-auto (hold to fire), 30-round mag, higher DPS, slight spread increase over sustained fire
    - Shotgun: pump-action (slow fire rate), 6-shell tube, devastating close range, fires multiple rays in a cone
  - Weapon switching via 1/2/3 keys or scroll wheel
  - Hitscan raycasting for all weapons, shotgun fires 8 rays in spread pattern
  - Reload with R key, per-weapon ammo pools
  - Health system: 100 HP, damage from weapon hits, death triggers respawn at random spawn point after 2s delay
  - Pickup items on the arena: health pack (+50 HP, green glow), ammo crate (refills current weapon, orange glow), pickups respawn 15s after collection
  - HUD: health bar (bottom left), ammo counter "mag/reserve" (bottom right), crosshair (center), current weapon name/icon indicator
  - Muzzle flash effect on fire (light flash + particles), bullet impact sparks
- **Assets:**
  - `handgun` GLB model (`assets/glb/handgun.glb`) — scale to 0.3m long
  - `rifle` GLB model (`assets/glb/rifle.glb`) — scale to 0.7m long
  - `shotgun` GLB model (`assets/glb/shotgun.glb`) — scale to 0.8m long
  - `health_pickup` GLB model (`assets/glb/health_pickup.glb`) — scale to 0.3m
  - `ammo_crate` GLB model (`assets/glb/ammo_crate.glb`) — scale to 0.3m
- **Verify:** First-person view shows the player can sprint, slide (camera lowers, speed boost), and mantle over low cover. All three weapons are switchable with distinct fire behaviors. HUD displays health and ammo. Shooting at walls produces impact effects. Picking up health/ammo items updates HUD values.

## 3. Bot AI & Deathmatch
- **Status:** pending
- **Depends on:** 1, 2
- **Targets:** scenes/bot.tscn, scenes/build_bot.gd, scenes/main.tscn, scenes/build_main.gd, scripts/bot_controller.gd, scripts/game_manager.gd, scripts/hud_controller.gd
- **Goal:** Add 4 AI opponents and the competitive deathmatch game loop — bots that navigate, fight, and die using the same combat systems as the player.
- **Requirements:**
  - 4 bot CharacterBody3D instances using NavigationAgent3D for pathfinding on the baked navmesh
  - Bot AI state machine: patrol (wander between random nav points) → chase (move toward visible target) → engage (stop and shoot at target in range) → retreat (seek cover when health < 30%)
  - Target selection: nearest visible enemy via raycast line-of-sight check, re-evaluate every 0.5s
  - Bots use the same weapon/damage/health/respawn systems as the player
  - Bots select weapon by range: shotgun close (<8m), rifle medium (8-25m), handgun fallback
  - Bot accuracy: slight random spread added to aim direction so they're challenging but beatable
  - Kill feed: text overlay showing "[killer] killed [victim]" fading after 3s, stacks up to 4 entries
  - Score tracking: kill count per combatant (player + 4 bots)
  - Scoreboard: Tab key shows ranked list of all combatants with kill/death counts
  - Match runs continuously (no round end — perpetual deathmatch)
- **Assets:**
  - `bot` GLB model (`assets/glb/bot.glb`) — scale to 1.8m tall
- **Verify:** Four bots are visible navigating the arena, engaging each other and the player in combat. Kill feed appears when kills happen. Tab scoreboard shows all combatants ranked by kills. Bots respawn after death and resume fighting.

## 4. Presentation Video
- **Status:** pending
- **Depends on:** 1, 2, 3
- **Targets:** test/presentation.gd, screenshots/presentation/gameplay.mp4
- **Goal:** Create a ~30-second cinematic video showcasing the completed game.
- **Requirements:**
  - Write test/presentation.gd — a SceneTree script (extends SceneTree)
  - Showcase representative gameplay via simulated input or scripted animations
  - ~900 frames at 30 FPS (30 seconds)
  - Use Video Capture from godot-capture (AVI via --write-movie, convert to MP4 with ffmpeg)
  - Output: screenshots/presentation/gameplay.mp4
  - Smooth camera work (orbits, tracking shots, dolly moves), good lighting (DirectionalLight3D key + fill/rim), post-processing (glow/bloom, SSAO, SSR, ACES tonemapping, volumetric fog)
- **Verify:** A smooth MP4 video showing polished gameplay with no visual glitches.
