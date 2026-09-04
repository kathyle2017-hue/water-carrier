extends SceneTree

## Opening flood days and the household reached through the real day adapter.
var failures := 0
var _save_path := ""
var _old_save := ""
var _old_day := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_old_save = OS.get_environment("WATER_CARRIER_SAVE_PATH")
	_old_day = OS.get_environment("WATER_CARRIER_DAY")
	_save_path = OS.get_temp_dir().path_join("water-carrier-flood-%s.json" % Time.get_ticks_usec())
	OS.set_environment("WATER_CARRIER_SAVE_PATH", _save_path)
	OS.set_environment("WATER_CARRIER_DAY", "")
	for day in 3:
		await _test_quiet_day(day)
	await _test_school_evening()
	DirAccess.remove_absolute(_save_path)
	OS.set_environment("WATER_CARRIER_SAVE_PATH", _old_save)
	OS.set_environment("WATER_CARRIER_DAY", _old_day)
	if failures == 0:
		print("flood and household ok: opening days, recurring rain, Talk, Father's Fan")
	quit(1 if failures else 0)


func _load_day(chapter: String, day: int) -> Node2D:
	var error := DayMemoryStore.new(_save_path).remember_day(false, false, {
		"chapter": chapter, "day": day, "saw_1975": true,
	})
	_expect(error == OK, "isolated chapter fixture saves")
	var scene: Node2D = load("res://scenes/water_run.tscn").instantiate()
	root.add_child(scene)
	await _settle()
	return scene


func _test_quiet_day(day: int) -> void:
	var scene = await _load_day("quiet", day)
	_expect(scene.story.day == day and scene.story.chapter == "quiet", "fixture opens the chosen quiet-year day")
	_expect(scene.world.has_node("StreetWater"), "street water remains visible in later mùa mưa")
	var ruin: Node2D = scene.world.get_node_or_null("NeighborsHouse")
	_expect((ruin != null) == (day < 2), "the ruined neighbors' house belongs only to the opening 1978 days")
	if day < 2 and ruin != null:
		_expect(not ruin.find_children("Neighbor*", "Sprite2D", false, false).is_empty(), "the opening flood shows neighbors beside the house")
		scene.carrier.global_position = Vector2(500, 114)
		await _settle()
		await _shot("flood-day-%d" % day)
	# Resolve the morning using its public play-facing actions, then let the
	# real adapter route Groceries and Sewing into the household.
	scene.run.enter_fill(true)
	scene.run.interact()
	scene.run.advance(1.9, Vector2.ZERO, false)
	scene.run.enter_fill(false)
	scene.run.enter_unload(true)
	scene.run.interact()
	scene.run.advance(1.5, Vector2.ZERO, false)
	scene.groceries.enter_dong(true)
	scene.groceries.interact()
	scene.groceries.advance(1.6)
	scene.groceries.enter_household(true)
	await _settle()
	_expect(scene.activity != null, "morning work reaches Sewing through the adapter")
	if scene.activity != null:
		scene.activity.state.skip()
	await _settle()
	_expect(scene.evening.started, "Sewing's public outcome reaches Evening")
	_expect(scene.world.get_node("Household").father_home == false, "Father stays absent during the quiet year")
	await _interact()
	var talk: String = scene.get_node("HUD/Feeling").text
	_expect(talk.contains("died") == (day == 1), "neighbor deaths appear only on the second 1978 opening day")
	if day == 0:
		_expect(talk.contains("house is ruined"), "the first opening day speaks about the ruined house")
	if day == 2:
		_expect(not talk.contains("neighbors"), "later rain does not repeat the 1978 loss")
	await _shot("quiet-evening-%d" % day)
	scene.queue_free()
	await _settle()


func _test_school_evening() -> void:
	var scene = await _load_day("school", 0)
	var school: SchoolState = scene.activity.state
	school.set_at_class(true)
	for step in 3:
		school.interact()
	school.set_at_home(true)
	await _settle()
	_expect(scene.evening.started and scene.evening.father_home, "the early school day reaches Father's evening bowl")
	_expect(scene.world.get_node("Household").father_home, "the household view includes Father and Mother's Fan")
	_expect(not scene.carrier.get_node("Yoke").is_visible_in_tree(), "the school-season household has no đòn gánh")
	await _interact()
	_expect(scene.get_node("HUD/Feeling").text.contains("Mother fans Father's bowl"), "Talk describes the Fan only when Father is at dinner")
	await _shot("school-evening-fan")
	scene.queue_free()
	await _settle()


func _shot(name: String) -> void:
	var directory := OS.get_environment("WATER_CARRIER_FLOOD_SHOTS")
	if directory == "":
		return
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(directory.path_join(name + ".png"))


func _interact() -> void:
	Input.action_press("interact")
	await physics_frame
	await process_frame
	Input.action_release("interact")
	await _settle()


func _settle() -> void:
	for frame in 3:
		await physics_frame
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
