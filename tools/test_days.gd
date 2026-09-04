extends SceneTree

## Chapter/day wiring through saved Bed progress, real input, and scene observations.
## Stream and household placements are authored zone fixtures, as in smoke_water_run.
const MAIN = preload("res://scenes/water_run.tscn")
const STREAM := Vector2(888, 120)
const HOUSEHOLD := Vector2(232, 88)
const DONG := Vector2(360, 88)
var failures := 0
var _paths: Array[String] = []
var _old_save := ""
var _old_demo := ""

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_old_save = OS.get_environment("WATER_CARRIER_SAVE_PATH")
	_old_demo = OS.get_environment("WATER_CARRIER_DAY")
	OS.set_environment("WATER_CARRIER_DAY", "")
	Engine.time_scale = 10.0
	await _test_school_evening()
	await _test_quiet_parcel()
	await _test_quan_day()
	await _test_1975_cut_to_class()
	await _test_return_is_terminal()
	await _test_rejected_piece_returns_after_repair()
	Engine.time_scale = 1.0
	OS.set_environment("WATER_CARRIER_SAVE_PATH", _old_save)
	OS.set_environment("WATER_CARRIER_DAY", _old_demo)
	for path in _paths:
		DirAccess.remove_absolute(path)
	if failures == 0:
		print("available day integration checks passed")
	quit(1 if failures else 0)

func _open(chapter: String, day: int, saw_1975 := true, repair := false) -> Node2D:
	var path := OS.get_temp_dir().path_join("water-carrier-days-%s-%s.json" % [Time.get_ticks_usec(), _paths.size()])
	_paths.append(path)
	var memory := DayMemoryStore.new(path)
	_expect(memory.remember_day(false, false, {"chapter": chapter, "day": day, "needs_repair": repair, "saw_1975": saw_1975}) == OK, "the isolated day fixture saves")
	OS.set_environment("WATER_CARRIER_SAVE_PATH", path)
	var scene := MAIN.instantiate()
	root.add_child(scene)
	await _settle()
	return scene

func _water(scene: Node2D) -> void:
	scene.carrier.global_position = STREAM
	await _settle()
	await _press("interact")
	await create_timer(2.0).timeout
	_expect(scene.run.loaded, "Fill loads water through the real stream zone")
	scene.carrier.global_position = HOUSEHOLD
	await _settle()
	await _press("interact")
	await create_timer(1.6).timeout
	await _settle()
	_expect(scene.run.done, "Unload completes water through the real household zone")

func _walk_x(body: Node2D, target: float, action: String) -> void:
	Input.action_press(action)
	for tick in 240:
		await physics_frame
		await process_frame
		if not is_instance_valid(body):
			break
		if (action == "move_right" and body.position.x >= target) or (action == "move_left" and body.position.x <= target):
			break
	Input.action_release(action)
	await _settle()

func _activity_is(scene: Node2D, kind: String) -> bool:
	return scene.activity != null and scene.activity.scene_file_path == "res://scenes/%s.tscn" % kind

func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await process_frame
	Input.action_release(action)
	await _settle()

func _settle() -> void:
	for tick in 3:
		await physics_frame
		await process_frame

func _close(scene: Node2D) -> void:
	scene.queue_free()
	await process_frame
	await _settle()

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		failures += 1
		push_error("DAY INTEGRATION: " + message)
	return condition

func _deliver_parcel(scene: Node2D) -> void:
	_expect(scene.activity.state.movement_speed() == 0.0, "parcel cooking holds the road until food is ready")
	await _press("interact")
	await create_timer(2.0).timeout
	var walker: Node2D = scene.activity.get_node("WaterCarrier")
	await _walk_x(walker, 940, "move_right")
	await _press("interact")
	await create_timer(1.8).timeout
	_expect(not scene.activity.state.loaded, "Handoff leaves the bags light")
	await _walk_x(walker, 78, "move_left")
	await _settle()

func _sew_day(scene: Node2D) -> void:
	await _water(scene)
	if not _expect(scene.groceries.started, "ordinary sewing days retain morning groceries"):
		return
	scene.carrier.global_position = DONG
	await _settle()
	await _press("interact")
	await create_timer(1.8).timeout
	scene.carrier.global_position = HOUSEHOLD
	await _settle()
	if not _expect(_activity_is(scene, "sewing"), "bringing groceries home starts Sewing"):
		return
	for step in 3:
		await _press("interact")
		await create_timer(1.8).timeout

func _office_visit(scene: Node2D, reject: bool) -> void:
	var office: Node2D = scene.activity
	var where := func() -> Vector2: return office.state.carrier_position
	await _walk_position(where, Vector2(592, 104))
	await _press("interact")
	_expect(office.state.place == "Phú Hòa · Office hall", "real Office entry opens the authored hall")
	await _walk_position(where, Vector2(272, 92))
	await _press("interact")
	await _walk_position(where, Vector2(216, 108))
	await _press("interact")
	_expect(office.state.needs_repair == reject, "Evaluate judges the current finished or repaired piece")
	await _press("interact")
	await _walk_position(where, Vector2(40, 128))
	await _press("interact")
	await _walk_position(where, Vector2(40, 112))
	await _press("interact")
	await _settle()

func _walk_position(where: Callable, destination: Vector2) -> void:
	for tick in 240:
		var position: Vector2 = where.call()
		var difference := destination - position
		if difference.length() < 12.0:
			break
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		if absf(difference.x) > 7.0:
			Input.action_press("move_right" if difference.x > 0 else "move_left")
		if absf(difference.y) > 7.0:
			Input.action_press("move_down" if difference.y > 0 else "move_up")
		await physics_frame
		await process_frame
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	await _settle()
	_expect((where.call() as Vector2).distance_to(destination) < 20.0, "real Office walking reaches its interaction point")
func _test_school_evening() -> void:
	var scene = await _open("school", 0, false)
	if _expect(_activity_is(scene, "school"), "school starts at school without a morning water run"):
		_expect(not scene.carrier.is_visible_in_tree(), "the water-run body and yoke stay out of school")
		_expect(not scene.run.done and not scene.groceries.started, "school has no completed water or groceries")
		var pupil: Node2D = scene.activity.get_node("WaterCarrier")
		await _walk_x(pupil, 244, "move_right")
		for step in 3:
			await _press("interact")
		_expect(scene.activity.state.walking_home, "copy, remember, recite lead home")
		await _walk_x(pupil, 65, "move_left")
		await _settle()
		if _expect(scene.evening.started and scene.activity == null, "school returns to household Evening"):
			_expect(scene.evening.father_home, "Father is at the pre-1975 evening bowl")
			_expect(not scene.carrier.get_node("Yoke").is_visible_in_tree(), "school evening does not reveal the unused yoke")
			await _press("interact")
			_expect(scene.evening.feeling.contains("Father"), "school Talk includes Father")
	await _close(scene)

func _test_quiet_parcel() -> void:
	var scene = await _open("quiet", 5, true, true)
	_expect(scene.activity == null and scene.carrier.is_visible_in_tree(), "quiet-year parcel begins with water")
	await _water(scene)
	if _expect(_activity_is(scene, "parcel"), "Unload opens parcel cooking instead of groceries or sewing"):
		_expect(scene.run.done and not scene.groceries.started, "water is home before parcel food is cooked")
		await _deliver_parcel(scene)
		_expect(scene.evening.started and not scene.groceries.started, "quiet-year parcel leaves afternoon work out and reaches Evening")
		_expect(scene.story.needs_repair, "a parcel day preserves the waiting repair")
		for step in 3:
			await _press("interact")
			await create_timer(1.8).timeout
		await _press("next_chapter")
		_expect(not scene.evening.asleep, "N cannot abandon a rejected piece at the end of a parcel day")
		await _press("bed")
		var saved: Dictionary = DayMemoryStore.new(OS.get_environment("WATER_CARRIER_SAVE_PATH")).load_last_day().get("progress", {})
		_expect(saved.get("chapter") == "quiet" and saved.get("needs_repair") == true and saved.get("day") == 6, "ordinary Bed preserves repair for the next sewing day")
	await _close(scene)

func _test_quan_day() -> void:
	var scene = await _open("quan", 0)
	_expect(scene.activity == null and scene.carrier.is_visible_in_tree(), "quán day starts with water")
	await _water(scene)
	if _expect(_activity_is(scene, "quan"), "Unload starts the bike to quán"):
		_expect(not scene.groceries.started and scene.run.done, "quán skips mandatory groceries after water")
		Input.action_press("move_right")
		for tick in 160:
			await physics_frame
			await process_frame
			if scene.activity.state.working:
				break
		Input.action_release("move_right")
		_expect(scene.activity.state.working, "actual bike input crosses Tràng Tiền and arrives at quán")
		# A thin shift must still rejoin the household; wait through the real shift clock.
		Engine.time_scale = 80.0
		await create_timer(80.0).timeout
		Engine.time_scale = 10.0
		await _settle()
		_expect(scene.evening.started and scene.evening.bad_day, "a timed-out shift reaches Evening as a bad day")
	await _close(scene)

func _test_1975_cut_to_class() -> void:
	var scene = await _open("school", 2, false)
	if _expect(_activity_is(scene, "scene_1975"), "1975 opens its short scene inside the school season"):
		for beat in 3:
			await _press("interact")
		if _expect(_activity_is(scene, "school"), "1975 cuts directly back to Huế class"):
			_expect(scene.activity.start_in_class and not scene.activity.father_home, "class resumes without Father")
			_expect(scene.activity.get_node("WaterCarrier").position.x > 230, "the cut places her at class, not at the water run")
			_expect(not scene.story.needs_1975_scene, "the capture scene is marked seen for this day")
	await _close(scene)

func _test_return_is_terminal() -> void:
	var scene = await _open("return", 0)
	if _expect(_activity_is(scene, "return"), "Return opens its closing household scene"):
		await create_timer(2.0).timeout
		for beat in 3:
			await _press("interact")
		for beat in 2:
			await _press("interact")
		_expect(_activity_is(scene, "return") and not scene.evening.started, "Return stays at its last bowl rather than opening another day")
		_expect(not scene.carrier.is_visible_in_tree(), "Return never reveals a fresh water run")
		_expect(scene.activity.get_node("Mother/Fan").visible, "Mother fans Father's food at Return")
	await _close(scene)

func _test_rejected_piece_returns_after_repair() -> void:
	var scene = await _open("quiet", 3)
	var saved_path := OS.get_environment("WATER_CARRIER_SAVE_PATH")
	await _sew_day(scene)
	if not _expect(_activity_is(scene, "evaluate"), "finishing a piece opens the Office the same day"):
		await _close(scene)
		return
	await _office_visit(scene, true)
	if not _expect(scene.evening.started and scene.story.needs_repair and scene.evening.bad_day, "a rejected piece comes home to a bad Evening with repair owed"):
		await _close(scene)
		return
	# Complete Talk, Pot, and Broom through the same keys as play, then save at Bed.
	for step in 3:
		await _press("interact")
		await create_timer(1.8).timeout
	await _press("bed")
	var remembered := DayMemoryStore.new(saved_path).load_last_day()
	_expect(remembered.get("progress", {}).get("needs_repair", false), "Bed persists the rejected piece's repair obligation")
	_expect(remembered.get("progress", {}).get("day", -1) == 4, "Bed advances to the next sewing day")
	await _close(scene)
	# Reopen the real persisted day, without editing its repair state or progress.
	scene = MAIN.instantiate()
	root.add_child(scene)
	await _settle()
	_expect(scene.activity == null and scene.story.needs_repair, "repair day begins with morning water and keeps the returned piece")
	await _sew_day(scene)
	if _expect(_activity_is(scene, "evaluate"), "repair sewing sends the ready piece back to the Office"):
		await _office_visit(scene, false)
		_expect(scene.evening.started and not scene.story.needs_repair, "acceptance clears the repair obligation and returns to Evening")
	await _close(scene)
