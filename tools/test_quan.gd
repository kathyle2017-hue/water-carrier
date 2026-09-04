extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var quan = load("res://scripts/quan_state.gd").new()
	quan.start(false)
	_expect(quan.place_name() == "Trần Hưng Đạo", "the afternoon starts on the bike street")
	quan.advance(30.0)
	_expect(not quan.working, "waiting cannot ride the bike for the player")
	quan.move(Vector2.RIGHT, 4.0)
	_expect(quan.place_name() == "Tràng Tiền · Hương", "the bike crosses the named bridge over Hương")
	quan.move(Vector2.RIGHT, 4.0)
	_expect(quan.place_name() == "Thong Hoi", "the far bank leads to Thong Hoi")
	quan.move(Vector2.RIGHT, 4.0)
	_expect(quan.working, "riding to the café begins the shift")
	_expect(not quan.interact(), "orders cannot be taken from the doorway")
	for table in range(4):
		_walk_to(quan, quan.table_positions[table])
		_expect(quan.interact(), "take the order at a table")
		_expect(quan.table_status(table) == "ordered", "the table waits for its drink")
		_walk_to(quan, Vector2(40, 68))
		_expect(quan.interact(), "pick up the next ordered drink at the counter")
		_walk_to(quan, quan.table_positions[table])
		_expect(quan.interact(), "serve the drink at the matching table")
	_expect(quan.done and not quan.bad_day, "serving all inside and outside tables closes a good shift")
	var wet = load("res://scripts/quan_state.gd").new()
	wet.start(true)
	wet.move(Vector2.RIGHT, 1.6, true)
	_expect(wet.bad_day and wet.grip < 1.0, "hurrying a wet bike causes a recoverable fall")
	wet.advance(2.0)
	for stretch in range(3):
		wet.move(Vector2.RIGHT, 5.0)
	_expect(wet.working, "the wet-bike fall still allows arrival at work")
	wet.advance(76.0)
	_expect(wet.done and wet.bad_day, "a blown shift closes for Evening without a game-over")
	var activity = load("res://scenes/quan.tscn").instantiate()
	activity.rainy = false
	root.add_child(activity)
	await process_frame
	var origin: Vector2 = activity.state.position
	Input.action_press("move_right")
	for frame in range(8):
		await physics_frame
		await process_frame
	Input.action_release("move_right")
	_expect(activity.state.position.x > origin.x, "real scene directional input pedals the bike")
	for stretch in range(3):
		activity.state.move(Vector2.RIGHT, 4.0)
	_walk_to(activity.state, Vector2(104, 80))
	Input.action_press("interact")
	await physics_frame
	await process_frame
	Input.action_release("interact")
	_expect(activity.state.table_status(0) == "ordered", "real scene interaction takes a table order")
	var outcomes: Array[bool] = []
	activity.completed.connect(func(bad: bool): outcomes.append(bad))
	activity.state.advance(76.0)
	await physics_frame
	await process_frame
	_expect(outcomes == [true], "scene emits a bad shift outcome for Evening exactly once")
	activity.queue_free()
	await process_frame
	print("quán checks: %s failures" % failures)
	quit(1 if failures else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _walk_to(quan, destination: Vector2) -> void:
	var travel: Vector2 = destination - quan.position
	quan.move(travel.normalized(), travel.length() / 58.0)
