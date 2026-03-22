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
