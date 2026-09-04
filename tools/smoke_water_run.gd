extends SceneTree

## Headless check of the first water-run mock: Fill, then Unload.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/water_run.tscn")
	if packed == null:
		_fail("missing water_run scene")
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var state: Node = root.get_node("RunState")
	var world: Node2D = scene.get_node("World")
	var carrier: CharacterBody2D = scene.get_node("WaterCarrier")
	if world == null or carrier == null or state == null:
		_fail("world, water-carrier, or RunState missing")
		return

	if state.loaded:
		_fail("should start light")
		return

	var fill_pos := _mark(world, "F")
	carrier.global_position = fill_pos
	carrier.enter_fill(true)
	carrier._start_fill()
	await create_timer(1.9).timeout
	if not state.loaded:
		_fail("Fill did not load the jugs")
		return
	if state.filling:
		_fail("still filling")
		return

	var unload_pos := _mark(world, "U")
	carrier.global_position = unload_pos
	carrier.enter_unload(true)
	carrier._start_unload()
	await create_timer(1.5).timeout
	if state.loaded:
		_fail("Unload left the yoke loaded")
		return
	if not state.done:
		_fail("Unload did not finish the mock")
		return

	print("smoke ok: Fill then Unload")
	quit(0)


func _mark(world: Node, ch: String) -> Vector2:
	if world.has_method("spawn_point") and ch == "P":
		return world.spawn_point()
	var map: PackedStringArray = world.MAP
	var tile: int = world.TILE
	for y in map.size():
		var row: String = map[y]
		for x in row.length():
			if row[x] == ch:
				return Vector2(x * tile + tile / 2.0, y * tile + tile / 2.0)
	_fail("mark %s missing" % ch)
	return Vector2.ZERO


func _fail(message: String) -> void:
	push_error(message)
	print("SMOKE FAIL: ", message)
	quit(1)
