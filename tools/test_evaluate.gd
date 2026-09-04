extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var script = load("res://scripts/evaluate_state.gd")
	if script == null:
		_expect(false, "Evaluate has a play-facing route")
	else:
		var state = script.new()
		state.start(false)
		_expect(not state.interact(), "Evaluate cannot happen at home")
		_walk_to(state, Vector2(592, 104))
		_expect(state.interact() and state.place == "Phú Hòa · Office hall", "the city walk enters a separate Office hall")
		_expect(not state.interact(), "the entrance is not the QA desk")
		_walk_to(state, Vector2(272, 92))
		_expect(state.interact() and state.place == "Phú Hòa · Military QA", "the hall leads to military QA")
		_expect(not state.interact(), "the piece must reach the desk")
		_walk_to(state, Vector2(216, 108))
		_expect(state.interact() and state.needs_repair and state.bad_day, "QA rejects the unfinished seam for later repair")
		_expect(not state.done, "rejection still requires a walk home")
		_expect(state.interact(), "a rejected piece can leave QA")
		_walk_to(state, Vector2(40, 128))
		_expect(state.interact(), "she leaves by the hall entrance")
		_expect(not state.done, "leaving the Office still requires the city walk home")
		_walk_to(state, Vector2(40, 112))
		_expect(state.interact() and state.done and state.needs_repair, "home completes the bad day visit with repair still due")
		_expect(not state.interact(), "a completed visit cannot restart")
		state = script.new()
		state.start(true)
		_walk_to(state, Vector2(592, 104))
		state.interact()
		_walk_to(state, Vector2(272, 92))
		state.interact()
		_walk_to(state, Vector2(216, 108))
		state.interact()
		_expect(not state.needs_repair and not state.bad_day, "a repaired piece is accepted on the later visit")
	await _test_real_scene()
	if failures == 0:
		print("evaluate ok")
	quit(1 if failures else 0)


func _walk_to(state, target: Vector2) -> void:
	for step in range(800):
		var offset: Vector2 = target - state.carrier_position
		if offset.length() < 1.0:
			return
		state.move(offset.limit_length(1.0), minf(1.0 / 30.0, offset.length() / 58.0))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _test_real_scene() -> void:
	var scene_file = load("res://scenes/evaluate.tscn")
	if scene_file == null:
		_expect(false, "Evaluate has an authored scene")
		return
	var scene = scene_file.instantiate()
	scene.piece_repaired = true
	var outcomes: Array[bool] = []
	scene.completed.connect(func(bad: bool): outcomes.append(bad))
	root.add_child(scene)
	await _settle()
	var initial: Vector2 = scene.state.carrier_position
	Input.action_press("move_right")
	await _settle()
	Input.action_release("move_right")
	_expect(scene.state.carrier_position.x > initial.x, "real movement input walks the piece toward the Office")
	await _interact()
	_expect(outcomes.is_empty(), "interacting on the road does not complete Evaluate")
	_walk_to(scene.state, Vector2(592, 104))
	await _interact()
	_expect(scene.get_node("Place").text == "Phú Hòa · Office hall", "real input enters the crowded Office hall")
	_walk_to(scene.state, Vector2(272, 92))
	await _interact()
	_walk_to(scene.state, Vector2(216, 108))
	await _interact()
	_expect(scene.get_node("Feeling").text.begins_with("Accepted."), "the repaired piece reaches the visible QA verdict")
	_expect(outcomes.is_empty(), "acceptance still waits for the walk home")
	await _interact()
	_walk_to(scene.state, Vector2(40, 128))
	await _interact()
	_walk_to(scene.state, Vector2(40, 112))
	await _interact()
	_expect(outcomes == [false] and not scene.needs_repair, "returning home reports acceptance once to the Day")
	await _interact()
	_expect(outcomes.size() == 1, "repeated input cannot complete the visit twice")
	scene.queue_free()
	await process_frame


func _interact() -> void:
	Input.action_press("interact")
	await _settle()
	Input.action_release("interact")
	await _settle()


func _settle() -> void:
	for frame in range(3):
		await physics_frame
		await process_frame
