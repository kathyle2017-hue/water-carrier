extends Node2D

@onready var world: Node2D = $World
@onready var carrier: CharacterBody2D = $WaterCarrier
@onready var hud: CanvasLayer = $HUD

var run: WaterRunState
var groceries := GroceriesState.new()
var evening := EveningState.new()
var story: ChapterProgress
var activity: Node2D
var _memory: DayMemoryStore
var _remembered := false
var _day_bad := false
var _change_chapter := false
var _activity_finishing := false

func _ready() -> void:
	_memory = DayMemoryStore.new(_save_path())
	var last_day := _memory.load_last_day()
	story = ChapterProgress.new(last_day.get("progress", {}))
	# Isolated demos and tests can enter an ordinary day without changing a save.
	var demo := OS.get_environment("WATER_CARRIER_DAY")
	if demo in ["quiet", "quan", "school", "return"]:
		story = ChapterProgress.new({"chapter": demo, "day": 2 if demo == "quiet" else 0})
	run = WaterRunState.new(bool(last_day.get("broom_skipped", false)))
	_day_bad = run.bad_day
	carrier.setup(run, groceries)
	hud.setup(run, groceries, evening)
	run.changed.connect(_continue_after_unload)
	groceries.changed.connect(_continue_after_groceries)
	evening.changed.connect(_remember_at_bed)
	carrier.global_position = world.spawn_point()
	carrier.setup_camera(world.map_pixel_size())
	var rain := world.get_node_or_null("Rain")
	if rain is CPUParticles2D:
		carrier.attach_rain(rain)
	_connect_zones()
	if story.chapter == "return":
		_open_activity("return")
	elif story.needs_1975_scene:
		_open_activity("scene_1975")
	elif story.day_kind == "school":
		_open_activity("school", {"father_home": story.father_home})
	else:
		world.set_flood(story.flood_opening, story.day)
	var shot_path := OS.get_environment("WATER_CARRIER_SHOT")
	if shot_path != "":
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var err := image.save_png(shot_path)
		print("screenshot ", shot_path, " err=", err)
		get_tree().quit()

func _physics_process(delta: float) -> void:
	if activity != null:
		return
	if not run.done and not evening.started:
		run.set_place(world.place_at(carrier.global_position.x))
	if groceries.started and not groceries.done:
		var was_busy := groceries.busy
		groceries.advance(delta)
		if not was_busy and Input.is_action_just_pressed("interact"):
			groceries.interact()
		if Input.is_action_just_pressed("skip"):
			groceries.skip()
		return
	if not evening.started:
		return
	if evening.asleep:
		if not _remembered and Input.is_action_just_pressed("bed"):
			_remember_at_bed()
		if _remembered and Input.is_action_just_pressed("interact"):
			get_tree().reload_current_scene()
		return
	var was_busy := evening.busy
	evening.advance(delta)
	if was_busy:
		return
	if Input.is_action_just_pressed("interact"):
		evening.interact()
	elif Input.is_action_just_pressed("bed"):
		evening.sleep()
	elif story.can_change_chapter and Input.is_action_just_pressed("next_chapter"):
		_change_chapter = true
		if not evening.sleep():
			_change_chapter = false
	_update_bed_prompt()

func _continue_after_unload() -> void:
	if not run.done or groceries.started or activity != null or evening.started:
		return
	_day_bad = _day_bad or run.bad_day
	match story.day_kind:
		"parcel":
			_open_activity.call_deferred("parcel")
		"quan":
			_open_activity.call_deferred("quan")
		_:
			groceries.start()

func _continue_after_groceries() -> void:
	if groceries.done and activity == null and not evening.started:
		_day_bad = _day_bad or groceries.bad_day
		_open_activity.call_deferred("sewing", {"finish_piece": story.finish_piece_today, "needs_repair": story.needs_repair})

func _open_activity(kind: String, options: Dictionary = {}) -> void:
	if activity != null:
		return
	world.hide()
	carrier.hide()
	carrier.set_physics_process(false)
	carrier.camera.enabled = false
	hud.hide()
	activity = load("res://scenes/%s.tscn" % kind).instantiate()
	for key in options:
		activity.set(key, options[key])
	activity.completed.connect(func(bad: bool):
		if not _activity_finishing:
			_activity_finishing = true
			_activity_done.call_deferred(kind, bad)
	)
	add_child(activity)

func _activity_done(kind: String, bad: bool) -> void:
	_day_bad = _day_bad or bad
	if kind == "return":
		# The last scene remains on its closing bowl; no new season follows it.
		return
	var piece_finished := false
	if kind == "sewing":
		piece_finished = activity.piece_finished
	if kind == "evaluate":
		story.needs_repair = activity.needs_repair
	remove_child(activity)
	activity.queue_free()
	activity = null
	_activity_finishing = false
	if kind == "scene_1975":
		story.see_1975()
		_open_activity("school", {"father_home": false, "start_in_class": true})
	elif kind == "sewing" and piece_finished and story.finish_piece_today:
		_open_activity("evaluate", {"piece_repaired": story.needs_repair})
	else:
		_start_evening()

func _start_evening() -> void:
	world.show()
	carrier.show()
	carrier.yoke.hide()
	carrier.camera.enabled = true
	carrier.global_position = world.spawn_point()
	carrier.set_physics_process(false)
	hud.show()
	world.show_household(story.father_home)
	evening.start(_day_bad, story.father_home, story.day if story.flood_opening else -1)
	_update_bed_prompt()

func _update_bed_prompt() -> void:
	if evening.asleep and _remembered:
		hud.prompt_label.text = "E  Next day"
	elif evening.can_sleep and story.needs_repair:
		hud.help_label.text = "B sleeps. Repair the returned piece before leaving this chapter."
	elif story.can_change_chapter and evening.can_sleep:
		hud.help_label.text = "B sleeps. N sleeps and moves to the next chapter."

func _remember_at_bed() -> void:
	if not evening.asleep or _remembered:
		return
	var next := ChapterProgress.new(story.snapshot())
	next.finish_day(_change_chapter)
	var error := _memory.remember_day(evening.bad_day, evening.broom_skipped, next.snapshot())
	if error != OK:
		push_error("Bed could not remember the day: %s" % error_string(error))
		hud.notice_label.text = "Bed could not save. Free disk space and press B to retry."
		return
	_remembered = true
	_update_bed_prompt()

func _save_path() -> String:
	var override := OS.get_environment("WATER_CARRIER_SAVE_PATH")
	return override if override != "" else DayMemoryStore.DEFAULT_PATH

func _connect_zones() -> void:
	var fill: Area2D = world.get_node("FillZone")
	var unload: Area2D = world.get_node("UnloadZone")
	var dong: Area2D = world.get_node("DongZone")
	fill.body_entered.connect(func(body):
		if body == carrier:
			run.enter_fill(true)
	)
	fill.body_exited.connect(func(body):
		if body == carrier:
			run.enter_fill(false)
	)
	unload.body_entered.connect(func(body):
		if body == carrier:
			run.enter_unload(true)
			groceries.enter_household(true)
	)
	unload.body_exited.connect(func(body):
		if body == carrier:
			run.enter_unload(false)
			groceries.enter_household(false)
	)
	dong.body_entered.connect(func(body):
		if body == carrier:
			groceries.enter_dong(true)
	)
	dong.body_exited.connect(func(body):
		if body == carrier:
			groceries.enter_dong(false)
	)
