# Playable slice checks

Use Godot 4.7. Run the complete check from the repository root:

```sh
./tools/test.sh
```

The runner finds `godot` on PATH or the macOS application at
`/Applications/Godot.app`. Set `GODOT_BIN` to use another executable. It imports
assets, checks every GDScript, then runs every test and smoke script. Engine errors fail
the check even when Godot returns exit code zero.

For a focused check after assets have been imported:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/test_water_run.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/test_groceries.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/test_evening.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/smoke_water_run.gd
```

- `test_water_run.gd` exercises the Water run interface used by play: zone
  presence, interaction, elapsed time, movement, and Glass. It checks Fill,
  Unload, refusal of unavailable interactions, spill/refill, persistent Bad day,
  coherent notifications, and independent runs. It advances time directly;
  repeated Glass contacts make the spill check independent of random drift.
- `test_evening.gd` exercises Evening and Bed through their play-facing actions.
  It checks good- and Bad-day Talk, the short chop / stir / serve Pot beat,
  completing or skipping Broom, Bed persistence, and the next-morning hangover.
- `test_groceries.gd` exercises the ordinary Groceries walk and Đông stall. It
  checks the post-Unload gate, ordinary movement, list / pay or barter / bag,
  and the walk home.
- `smoke_water_run.gd` loads the real scene, positions the water-carrier at
  authored fixture locations, waits for physics zones, and presses actual input
  actions. It checks zone entry and exit, busy movement, the HUD and jugs,
  Unload into Groceries, the distinct Đông location, inactive Glass and hidden
  đòn gánh on that walk, the return into Evening, one playable body, Bed
  persistence, next-morning state, and Glass contact. It does not call private
  interaction methods or parse the map. If the road changes, update its fixture
  coordinates.

The scene owns a fresh `WaterRunState`, `GroceriesState`, and `EveningState`; the
water-carrier and HUD observe them. Gameplay rules belong to those modules,
while movement, drawing, their explicit handoffs, and the Bed persistence
boundary stay in the Godot scene. This avoids adding a general road or Day
framework.

Standalone activities can be run directly from their scenes.
Sewing: `scenes/sewing.tscn`; E unrolls, works, and packs; X skips the must.
Parcel: `scenes/parcel.tscn`; cook, walk with Mother to Ái Thu, Handoff, return.
