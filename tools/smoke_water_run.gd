extends SceneTree

## Real Godot zones, input, timers, and presentation for the authored Water run.
## Coordinates are fixture locations on this road, not a copy of its map parser.
const STREAM := Vector2(888, 120)
const HOUSEHOLD := Vector2(232, 88)
const DONG := Vector2(360, 88)
const ROAD := Vector2(600, 120)
const GLASS := Vector2(392, 96) # Feet sit eight pixels below the body origin.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_path := OS.get_temp_dir().path_join("water-carrier-smoke-%s.json" % Time.get_ticks_usec())
	OS.set_environment("WATER_CARRIER_SAVE_PATH", save_path)
	OS.set_environment("WATER_CARRIER_DAY", "quiet")
	var scene = load("res://scenes/water_run.tscn").instantiate()
	root.add_child(scene)
	var carrier: CharacterBody2D = scene.get_node("WaterCarrier")
	var run: WaterRunState = scene.run
	await _settle()
	if not _expect(not run.loaded, "should start light"):
		return
	await _interact()
	if not _expect(not run.filling, "interact outside stream must do nothing"):
		return

	await _walk_to(carrier, STREAM)
	if not _expect(run.prompt == "E  Fill", "real stream zone offers Fill"):
		return
	await _walk_to(carrier, ROAD)
	await _interact()
	if not _expect(not run.filling and run.prompt == "", "leaving stream removes Fill eligibility"):
		return
	await _walk_to(carrier, STREAM)
	await _interact()
	if not _expect(run.filling, "input starts Fill"):
		return
	Input.action_press("move_left")
	await _settle()
	Input.action_release("move_left")
	if not _expect(carrier.global_position.is_equal_approx(STREAM), "Fill holds the water-carrier still"):
		return
	await create_timer(1.9).timeout
	if not _expect(run.loaded and not run.busy, "Fill loads the jugs"):
		return
	if not _expect(carrier.get_node("Yoke/JugLeft").frame == 1, "loaded jugs are drawn"):
		return
	await _walk_to(carrier, ROAD)
	await _interact()
	if not _expect(not run.unloading, "cannot Unload away from household"):
		return
	await _walk_to(carrier, HOUSEHOLD)
	if not _expect(run.prompt == "E  Unload", "real household zone offers Unload"):
		return
	await _walk_to(carrier, ROAD)
	await _interact()
	if not _expect(not run.unloading, "leaving household removes Unload eligibility"):
		return
	await _walk_to(carrier, HOUSEHOLD)
	await _interact()
	await create_timer(1.5).timeout
	if not _expect(run.done and not run.loaded, "Unload completes the Water run"):
		return
	if not _expect(not carrier.get_node("Yoke").visible, "Unload sets the đòn gánh down"):
		return
	if not _expect(scene.get_node("HUD/Notice").text == "The household has water.", "HUD receives the complete outcome"):
		return
	if not _expect(scene.groceries.started and not scene.evening.started, "Unload starts the separate walk to Đông"):
		return
	if not _expect(not carrier.get_node("Yoke").visible and scene.get_node("HUD/Prompt").text == "Walk to Đông", "shopping starts only after the đòn gánh is set down"):
		return
	await _walk_to(carrier, GLASS)
	if not _expect(not run.bad_day and run.notice == "The household has water.", "Glass does not belong to the walk to Đông"):
		return
	await _walk_to(carrier, DONG)
	if not _expect(scene.groceries.prompt == "E  Groceries", "the real Đông zone offers Groceries"):
		return
	if not _expect(scene.get_node("HUD/Place").text == "Đông · Phú Bình", "Đông is a named Phú Bình spot separate from Fill"):
		return
	await _interact()
	Input.action_press("move_right")
	await _settle()
	Input.action_release("move_right")
	if not _expect(carrier.global_position.is_equal_approx(DONG), "the short stall beat holds the water-carrier still"):
		return
	await create_timer(1.7).timeout
	if not _expect(scene.groceries.prompt == "Walk home", "list, pay or barter, and bag lead home"):
		return
	await _walk_to(carrier, ROAD)
	await _walk_to(carrier, HOUSEHOLD)
	if not _expect(scene.groceries.done and not scene.evening.started and scene.activity != null, "walking home starts daytime Sewing"):
		return
	for step in 3:
		await _interact()
		await create_timer(1.6).timeout
	if not _expect(scene.evening.started, "Sewing continues into Evening"):
		return
	if not _expect(scene.get_node("HUD/Help").visible, "household controls reappear after the loaded-water meter"):
		return
	if not _expect(scene.get_node("HUD/Prompt").text == "E  Talk", "Evening opens after Groceries"):
		return
	if not _expect(scene.find_children("*", "CharacterBody2D", true, false).size() == 1, "only the water-carrier is playable"):
		return
	await _interact()
	await create_timer(1.3).timeout
	await _interact()
	await create_timer(1.7).timeout
	if not _expect(scene.get_node("HUD/Prompt").text == "E  Broom    B  Bed", "Talk and the short Pot beat reach the night choice"):
		return
	Input.action_press("bed")
	await physics_frame
	await process_frame
	Input.action_release("bed")
	await _settle()
	if not _expect(scene.evening.asleep, "Bed closes the Evening"):
		return
	var remembered := DayMemoryStore.new(save_path).load_last_day()
	if not _expect(remembered.get("broom_skipped") == true, "Bed remembers the skipped Broom"):
		return

	scene.queue_free()
	await process_frame
	scene = load("res://scenes/water_run.tscn").instantiate()
	root.add_child(scene)
	carrier = scene.get_node("WaterCarrier")
	run = scene.run
	await _settle()
	if not _expect(not run.done and run.bad_day and not run.loaded, "a fresh scene owns a new run with the Bad day hangover"):
		return
	if not _expect(run.notice == "Leaves from last night still cling to the yard. Mother looks once.", "the next morning loads the remembered Broom consequence"):
		return
	await _walk_to(carrier, GLASS)
	if not _expect(run.bad_day, "real Glass contact reaches Water run rules"):
		return
	DirAccess.remove_absolute(save_path)
	OS.set_environment("WATER_CARRIER_SAVE_PATH", "")
	print("smoke ok: real zones, Fill, Unload, Đông, Groceries, Evening, Bed memory, Glass")
	quit(0)


func _walk_to(carrier: CharacterBody2D, position: Vector2) -> void:
	# Place the body, then let the actual physics zones report entry and exit.
	carrier.global_position = position
	await _settle()


func _interact() -> void:
	Input.action_press("interact")
	await physics_frame
	await process_frame
	Input.action_release("interact")
	await _settle()


func _settle() -> void:
	for i in 3:
		await physics_frame
		await process_frame


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error("SMOKE FAIL: " + message)
		quit(1)
	return condition
