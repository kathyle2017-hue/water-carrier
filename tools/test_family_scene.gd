extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/scene_1975.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var outcomes: Array[bool] = []
	scene.completed.connect(func(bad: bool): outcomes.append(bad))
	_expect(scene.get_node("Place").text.contains("Đà Nẵng"), "1975 stays with her in Đà Nẵng")
	_expect(scene.get_node_or_null("Father") == null, "Father's capture has no second camera or playable body")
	await _interact()
	_expect(scene.get_node("Talk").text.contains("Thuận An"), "Thuận An is named in the news, offscreen")
	await _interact()
	_expect(outcomes.is_empty(), "The final beat waits for the player to read it")
	await _interact()
	await _interact()
	_expect(outcomes == [false], "The short 1975 scene completes exactly once")
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/return.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var father: Sprite2D = scene.get_node("Father")
	var entry: Vector2 = father.position
	var returned: Array[bool] = []
	scene.completed.connect(func(bad: bool): returned.append(bad))
	await _interact()
	_expect(scene.get_node("Talk").text.contains("1988"), "Talk waits while Father walks in")
	await create_timer(0.3).timeout
	_expect(father.position.x < entry.x, "Father visibly walks in instead of appearing at the bowl")
	_expect(not scene.get_node("Mother/Fan").visible, "Mother waits until Father reaches the bowl before fanning")
	await create_timer(2.0).timeout
	_expect(scene.get_node("Mother/Fan").visible, "Mother fans while Father is at the bowl")
	_expect(scene.get_node_or_null("Sister") != null and scene.get_node_or_null("WaterCarrier") != null, "Return includes Sister and the water-carrier")
	_expect(scene.find_children("*", "Sprite2D", true, false).size() == 4, "Return contains exactly the four household members, no children")
	for beat in 3:
		await _interact()
	await _interact()
	_expect(returned == [false], "Return finishes once without starting another school day")
	scene.queue_free()
	await process_frame
	if failures == 0:
		print("family scenes ok")
	quit(1 if failures else 0)

func _interact() -> void:
	Input.action_press("interact")
	await physics_frame
	await process_frame
	Input.action_release("interact")
	for frame in 3:
		await physics_frame
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
