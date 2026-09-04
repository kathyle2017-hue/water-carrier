extends SceneTree

var failures := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_cook_then_carry_food()
	_test_handoff_then_light_walk_home()
	await _test_real_scene_input()
	if failures == 0:
		print("parcel rules and scene input ok")
	quit(1 if failures else 0)

func _test_cook_then_carry_food() -> void:
	var parcel = load("res://scripts/parcel_state.gd").new()
	parcel.start(true)
	_expect(parcel.movement_speed() == 0.0, "cooking precedes the parcel road")
	_expect(parcel.interact(), "E begins the short cooking beat")
	parcel.advance(2.0)
	_expect(parcel.loaded, "food bags are heavy on the outward road")
	_expect(parcel.movement_speed() > 0.0, "cooked food can be carried out")
	_expect(not parcel.interact(), "Handoff cannot start away from Ái Thu")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_handoff_then_light_walk_home() -> void:
	var parcel = load("res://scripts/parcel_state.gd").new()
	parcel.start(false)
	var outward_speed: float = parcel.movement_speed()
	parcel.enter_household(true)
	_expect(not parcel.done, "home cannot complete an undelivered parcel")
	parcel.enter_gate(true)
	_expect(parcel.interact(), "Ái Thu offers a short Handoff")
	_expect(parcel.movement_speed() == 0.0, "give food and pause at the Gate")
	parcel.advance(0.7)
	_expect(parcel.movement_speed() == 0.0, "the moment is visible before turning home")
	parcel.advance(1.0)
	_expect(not parcel.loaded, "bags are empty after Handoff")
	_expect(parcel.movement_speed() > outward_speed, "the homeward walk is lighter")
	_expect(not parcel.done, "Handoff still requires a real walk home")
	parcel.enter_household(true)
	_expect(parcel.done, "arriving home leaves the day ready for evening")

func _test_real_scene_input() -> void:
	var scene = load("res://scenes/parcel.tscn").instantiate()
	scene.cook_first = false
	root.add_child(scene)
	await process_frame
	var player: Node2D = scene.get_node("WaterCarrier")
	var mother: Node2D = scene.get_node("Mother")
	var player_start := player.position
	var mother_start := mother.position
	Input.action_press("move_right")
	for tick in 24:
		await physics_frame
	Input.action_release("move_right")
	_expect(player.position.x > player_start.x + 8.0, "real walking input carries food along the road")
	_expect(mother.position.x > mother_start.x, "Mother follows as company")
	_expect(not scene.state.done, "walking outward cannot skip the parcel")
	Input.action_press("move_up")
	for tick in 6:
		await physics_frame
	Input.action_release("move_up")
	_expect(player.position.y < player_start.y, "the road accepts 3/4 vertical walking")
	var completions: Array[bool] = []
	scene.completed.connect(func(bad_day: bool): completions.append(bad_day))
	Engine.time_scale = 30.0
	Input.action_press("move_right")
	for tick in 120:
		await physics_frame
		if player.position.x >= 936:
			break
	Input.action_release("move_right")
	await physics_frame
	_expect(player.position.x >= 932, "a real outward walk reaches Ái Thu")
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for tick in 6:
		await physics_frame
	_expect(not scene.state.loaded and not scene.state.done, "Handoff turns the real scene toward home")
	Input.action_press("move_left")
	for tick in 120:
		await physics_frame
		if scene.state.done:
			break
	Input.action_release("move_left")
	await physics_frame
	_expect(completions == [false], "walking home emits one evening handoff with no invented bad day")
	Engine.time_scale = 1.0
	scene.queue_free()
	await process_frame
