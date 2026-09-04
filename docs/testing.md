# Water run checks

Use Godot 4.7. Run the complete check from the repository root:

```sh
./tools/test.sh
```

The runner finds `godot` on PATH or the macOS application at
`/Applications/Godot.app`. Set `GODOT_BIN` to use another executable. It imports
assets, checks every GDScript, then runs both test files. Engine errors fail the
check even when Godot returns exit code zero.

For a focused check after assets have been imported:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/test_water_run.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/smoke_water_run.gd
```

- `test_water_run.gd` exercises the Water run interface used by play: zone
  presence, interaction, elapsed time, movement, and Glass. It checks Fill,
  Unload, refusal of unavailable interactions, spill/refill, persistent Bad day,
  coherent notifications, and independent runs. It advances time directly;
  repeated Glass contacts make the spill check independent of random drift.
- `smoke_water_run.gd` loads the real scene, positions the water-carrier at
  authored fixture locations, waits for physics zones, and presses actual input
  actions. It checks zone entry and exit, busy movement, the HUD and jugs,
  fresh-scene state, and Glass contact. It does not call private interaction
  methods or parse the map. If the road changes, update its fixture coordinates.

The scene owns a fresh `WaterRunState`; the water-carrier and HUD share it.
Gameplay rules belong to that module, while movement and drawing stay in Godot.
The scene connects the world's zones and reports the current place. This keeps
scene setup explicit without adding a general road or Day framework.
