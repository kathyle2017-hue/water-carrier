extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sewing = load("res://scripts/sewing_state.gd").new()
	sewing.start()
	_expect(sewing.interact(), "the household can unroll the piece")
	_expect(sewing.busy and not sewing.done, "unrolling takes a short moment")
	_expect(not sewing.interact(), "holding interact cannot skip unrolling")
	sewing.advance(0.8)
	_expect(sewing.interact(), "the water-carrier can work a section")
	sewing.advance(1.6)
	_expect(sewing.interact(), "ordinary sewing ends by packing the length")
	sewing.advance(0.8)
	_expect(sewing.done and not sewing.bad_day and not sewing.piece_finished,
		"a section fulfills Sewing without inventing a finished piece")
	_expect(not sewing.interact(), "completed Sewing cannot restart")
	var repaired = load("res://scripts/sewing_state.gd").new()
	repaired.start(true, true)
	repaired.interact()
	repaired.advance(0.8)
	_expect(repaired.prompt == "E  Repair the section", "a rejected piece returns as repair work")
	repaired.interact()
	repaired.advance(1.6)
	_expect(repaired.prompt == "E  Finish the piece", "a ready piece can be finished after work")
	repaired.interact()
	repaired.advance(0.8)
	_expect(repaired.done and repaired.piece_finished and not repaired.bad_day,
		"finished repairs release the piece for a later Office visit")
	var skipped = load("res://scripts/sewing_state.gd").new()
	skipped.start(true)
	skipped.interact()
	skipped.skip()
	skipped.advance(10.0)
	_expect(skipped.done and skipped.bad_day and not skipped.piece_finished,
		"leaving Sewing makes a Bad day and cannot finish the piece in the background")
	_expect(not skipped.skip(), "a resolved must cannot be skipped twice")
	await _test_scene()
	if failures == 0:
		print("sewing ok")
	quit(1 if failures else 0)


func _test_scene() -> void:
	var scene = load("res://scenes/sewing.tscn").instantiate()
	scene.finish_piece = true
	var outcomes: Array[bool] = []
	scene.completed.connect(func(bad: bool): outcomes.append(bad))
	root.add_child(scene)
	await process_frame
	for duration in [0.8, 1.6, 0.8]:
		Input.action_press("interact")
		await physics_frame
		await process_frame
		Input.action_release("interact")
		await create_timer(duration).timeout
	_expect(scene.state.done and scene.state.piece_finished, "real scene input completes a finished piece")
	_expect(outcomes == [false], "the scene reports completion once with the settled outcome")
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/sewing.tscn").instantiate()
	outcomes.clear()
	scene.completed.connect(func(bad: bool): outcomes.append(bad))
	root.add_child(scene)
	await process_frame
	var skip_key := InputEventKey.new()
	skip_key.physical_keycode = KEY_X
	skip_key.pressed = true
	Input.parse_input_event(skip_key)
	await process_frame
	skip_key.pressed = false
	Input.parse_input_event(skip_key)
	await process_frame
	_expect(scene.state.done and outcomes == [true], "X skips the must with a Bad day outcome")
	scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
