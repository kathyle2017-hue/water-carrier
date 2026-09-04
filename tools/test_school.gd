extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var school = load("res://scripts/school_state.gd").new()
	_expect(not school.interact(), "Class cannot start on the road")
	school.set_at_class(true)
	_expect(school.prompt == "E  Copy", "Arriving at class opens Copy")
	_expect(school.interact(), "Copy uses the play action")
	_expect(school.prompt == "E  Remember", "Copy leads to Remember")
	school.interact()
	_expect(school.prompt == "E  Recite", "Remember leads to Recite")
	school.interact()
	_expect(school.prompt == "Walk home" and not school.done, "Recite still requires the walk home")
	school.set_at_home(true)
	_expect(school.done and not school.bad_day, "A school day finishes at home without a clock penalty")
	var scene = load("res://scenes/school.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var carrier: Node2D = scene.get_node("WaterCarrier")
	var start: Vector2 = carrier.position
	Input.action_press("move_right")
	await _settle()
	Input.action_release("move_right")
	_expect(carrier.position.x > start.x, "Real movement input walks toward school")
	_expect(scene.find_child("Yoke", true, false) == null, "School has no yoke")
	carrier.position = Vector2(256, 112)
	await _settle()
	for step in 3:
		await _interact()
	_expect(scene.state.walking_home, "Real class interaction completes Copy, Remember, Recite")
	var results: Array[bool] = []
	scene.completed.connect(func(bad: bool): results.append(bad))
	carrier.position = Vector2(48, 112)
	await _settle()
	_expect(results == [false], "Coming home emits the school outcome once")
	scene.queue_free()
	await process_frame
	if failures == 0:
		print("school rules ok")
	quit(1 if failures else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _settle() -> void:
	for frame in 3:
		await physics_frame
		await process_frame

func _interact() -> void:
	Input.action_press("interact")
	await physics_frame
	await process_frame
	Input.action_release("interact")
	await _settle()
