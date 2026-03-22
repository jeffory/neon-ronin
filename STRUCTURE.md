# Neon Ronin

## Dimension: 3D

## Input Actions

| Action | Keys |
|--------|------|
| move_forward | W |
| move_back | S |
| move_left | A |
| move_right | D |
| jump | Space |
| sprint | Shift |
| crouch | Ctrl |
| shoot | Left Mouse Button |
| reload | R |
| weapon_1 | 1 |
| weapon_2 | 2 |
| weapon_3 | 3 |
| scoreboard | Tab |

## Scenes

### Main
- **File:** res://scenes/main.tscn
- **Root type:** Node3D
- **Children:** Level (instance), Player (instance), CanvasLayer (HUD)
- **Notes:** Spawns bots and pickups via GameManager on _ready

### Level
- **File:** res://scenes/level.tscn
- **Root type:** Node3D
- **Children:** NavigationRegion3D (with baked NavigationMesh), CSG geometry (buildings, streets, cover), OmniLight3D/SpotLight3D (neon lights), DirectionalLight3D (moonlight), WorldEnvironment, SpawnPoints (Node3D with Marker3D children), PickupSpots (Node3D with Marker3D children)

### Player
- **File:** res://scenes/player.tscn
- **Root type:** CharacterBody3D
- **Children:** CollisionShape3D (capsule ~1.8m), Head (Node3D at y=0.8), Camera3D (on Head), WeaponHolder (Node3D on Camera3D), RayCast3D (weapon range)

### Bot
- **File:** res://scenes/bot.tscn
- **Root type:** CharacterBody3D
- **Children:** CollisionShape3D (capsule ~1.8m), NavigationAgent3D, RayCast3D (line of sight), MeshInstance3D (bot model placeholder)

### HUD
- **File:** res://scenes/hud.tscn
- **Root type:** CanvasLayer
- **Children:** Control (full rect), HealthBar (ProgressBar, bottom-left), AmmoLabel (Label, bottom-right), Crosshair (TextureRect, center), WeaponLabel (Label, bottom-right), KillFeed (VBoxContainer, top-right), Scoreboard (PanelContainer, center, hidden by default)

### PickupHealth
- **File:** res://scenes/pickup_health.tscn
- **Root type:** Area3D
- **Children:** CollisionShape3D (sphere r=0.5), MeshInstance3D (placeholder cube, green emissive)

### PickupAmmo
- **File:** res://scenes/pickup_ammo.tscn
- **Root type:** Area3D
- **Children:** CollisionShape3D (sphere r=0.5), MeshInstance3D (placeholder cube, orange emissive)

## Scripts

### GameManager (Autoload)
- **File:** res://scripts/game_manager.gd
- **Extends:** Node
- **Signals emitted:** kill_registered(killer_name: String, victim_name: String), score_updated
- **Responsibilities:** Match state, kill/death tracking, spawn point management, bot spawning, pickup spawning

### PlayerController
- **File:** res://scripts/player_controller.gd
- **Extends:** CharacterBody3D
- **Attaches to:** Player:Player
- **Signals emitted:** died(entity_name: String), health_changed(hp: int)
- **Exports:** speed (5.0), sprint_speed (8.0), jump_velocity (5.0), mouse_sensitivity (0.002), max_health (100)

### WeaponManager
- **File:** res://scripts/weapon_manager.gd
- **Extends:** Node3D
- **Attaches to:** Player:Player/Head/Camera3D/WeaponHolder
- **Signals emitted:** weapon_switched(weapon_name: String), ammo_changed(mag: int, reserve: int)
- **Responsibilities:** Weapon switching, firing (hitscan raycast), ammo, reload, muzzle flash

### BotController
- **File:** res://scripts/bot_controller.gd
- **Extends:** CharacterBody3D
- **Attaches to:** Bot:Bot
- **Signals emitted:** died(entity_name: String), health_changed(hp: int)
- **Responsibilities:** AI state machine (patrol/chase/engage/retreat), navigation, target selection, weapon use

### HUDController
- **File:** res://scripts/hud_controller.gd
- **Extends:** CanvasLayer
- **Attaches to:** Main:CanvasLayer
- **Signals received:** PlayerController.health_changed, WeaponManager.ammo_changed, WeaponManager.weapon_switched, GameManager.kill_registered

### Pickup
- **File:** res://scripts/pickup.gd
- **Extends:** Area3D
- **Attaches to:** PickupHealth:PickupHealth, PickupAmmo:PickupAmmo
- **Signals received:** body_entered -> _on_body_entered
- **Exports:** pickup_type (String), heal_amount (50), respawn_time (15.0)

## Signal Map

- PlayerController.died -> GameManager._on_entity_died
- PlayerController.health_changed -> HUDController._on_health_changed
- BotController.died -> GameManager._on_entity_died
- WeaponManager.weapon_switched -> HUDController._on_weapon_switched
- WeaponManager.ammo_changed -> HUDController._on_ammo_changed
- GameManager.kill_registered -> HUDController._on_kill_registered
- Pickup.body_entered -> Pickup._on_body_entered

## Asset Hints

- Handgun 3D model (~0.3m long, sleek sci-fi pistol)
- Rifle 3D model (~0.7m long, futuristic assault rifle)
- Shotgun 3D model (~0.8m long, heavy sci-fi shotgun)
- Bot character 3D model (~1.8m tall cyberpunk humanoid soldier)
- Health pickup 3D model (~0.3m glowing med-kit)
- Ammo crate 3D model (~0.3m tech crate)
- Neon sign textures (3 variations, Japanese text, vivid colors, ~1m x 0.5m)
- Building facade texture (dark concrete/steel, tileable, 4m repeat)
- Street/ground texture (wet asphalt, tileable, 4m repeat)
- Night sky panorama (360° dark cyberpunk cityscape skyline)
