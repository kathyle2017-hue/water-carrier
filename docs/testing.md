# Playable slice checks

Use Godot 4.7. Run the complete check from the repository root:

```sh
./tools/test.sh
```

The runner finds `godot` on PATH or the macOS application at
`/Applications/Godot.app`. Set `GODOT_BIN` to use another executable. It imports
assets, checks every GDScript, and runs `tools/test_*.gd` and `tools/smoke_*.gd`.
Engine errors fail the check even when Godot returns exit code zero.

For a focused check after assets have been imported:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/test_sewing.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/test_days.gd
```

Tests exercise the play-facing action and state interfaces and real scene input.
Fixture positions place the water-carrier at authored locations, then allow
physics zones to report entry/exit. They do not call private scene interactions.

- `test_water_run.gd`: Fill, Unload, eligibility, spill/refill, Bad day, Glass,
  coherent notifications, and independent runs.
- `test_groceries.gd`: ordinary walk, list/pay-or-barter/bag, and coming home
  with groceries or an empty bag.
- `test_sewing.gd`: unroll/work/pack or finish, repair, skipping the must,
  scene input and once-only completion.
- `test_parcel.gd`: cooking, heavier bags outward, Ái Thu Handoff, lighter
  return, actual movement and Mother following.
- `test_school.gd`: classroom actions, walk home, and real movement input.
- `test_family_scene.gd`: the equal-sized 1975 and Return scenes, Father
  walking in and Mother's automatic Fan.
- `test_quan.gd`: bike route, wet grip and recoverable falls, orders,
  counter pickup, table service, and bad-shift continuation.
- `test_evaluate.gd`: Office route, rejection, repaired acceptance, and return.
- `test_evening.gd`: family presence, flood Talk, Pot, Broom, Bed, saved calendar
  and repair, and next-morning hangover.
- `test_chapters.gd`: biography order, separate day kinds, opening flood days,
  Evaluate/Parcel exclusion, repair persistence, and terminal Return.
- `test_days.gd` and `test_flood.gd`: integration across the real day scene,
  chapter-specific activities, family presentation and flood days.
- `smoke_water_run.gd`: actual water zones, HUD/jugs, groceries, sewing,
  evening, Bed persistence, next-morning state, and Glass.

The scene owns each day's state. Activities own their movement and drawing,
reporting their completed outcome to the day scene. The scene owns the explicit
handoffs; `ChapterProgress` owns the biography calendar. Bed saves the next day
and any piece still needing repair. Activities never write the save.

# Playing

Open `project.godot` and run. A new save begins in School. WASD/arrows move;
E/Space interacts. School proceeds through Copy, Remember, Recite, then home.
After two School days, the short 1975 scene leads straight into Huế class.
School parcel days skip class and have no water run.

In the quiet year, water leads to Đông, then Sewing, then Evening. X can leave
Groceries or Sewing unfinished, making a Bad day. Flooding opens the first two
days; later street water does not replay the neighbors' deaths. Finished pieces
travel to Phú Hòa that day. Rejected work is repaired on a later sewing day.
Parcel days replace that afternoon with cooking and the walk to Ái Thu.
An outstanding repair survives parcel days and must be accepted before the
player can leave the sewing era.

Quán days start with water, then bike and service. Shift hurries on the bike;
wet hurrying can cause a recoverable fall. At the café, E takes orders at tables,
collects drinks at the counter, and serves the matching table. Leaving early or
serving too little is a Bad day. Parcel days replace the shift.

Evening has Talk, Pot and Broom. B sleeps once Pot is done; skipping Broom is
felt next morning. E continues after Bed. Each season stays open for more days.
After six days, N at Bed sleeps and moves to the next chapter instead. The
school, sewing and quán seasons have the same minimum length. Return around
1988 is the final scene; there is no playable 1984–88 season or class afterward.

For isolated development demos, set `WATER_CARRIER_SAVE_PATH` to a temporary
file. `WATER_CARRIER_DAY=quiet`, `school`, `quan`, or `return` starts that demo on
each load. Clear the day override to exercise normal saved progression. The
standalone scenes under `scenes/` can also be run directly. Placeholder art
remains intentional; #5 awaits the human-supplied character pictures.
