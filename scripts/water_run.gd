extends Node2D

@onready var world: Node2D = $World
@onready var carrier: CharacterBody2D = $WaterCarrier
@onready var hud: CanvasLayer = $HUD

var run: WaterRunState
var groceries := GroceriesState.new()
var evening := EveningState.new()
var _memory: DayMemoryStore
var _remembered := false


func _ready() -> void:
	_memory = DayMemoryStore.new(_save_path())
	var last_day := _memory.load_last_day()
	run = WaterRunState.new(bool(last_day.get("broom_skipped", false)))
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
	var shot_path := OS.get_environment("WATER_CARRIER_SHOT")
	if shot_path != "":
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var err := image.save_png(shot_path)
		print("screenshot ", shot_path, " err=", err, " ", image.get_width(), "x", image.get_height())
		get_tree().quit()


func _physics_process(delta: float) -> void:
	if not run.done:
		run.set_place(world.place_at(carrier.global_position.x))
	if groceries.started and not groceries.done:
		groceries.advance(delta)
		if not groceries.busy and Input.is_action_just_pressed("interact"):
			groceries.interact()
		return
	if not evening.started or evening.asleep:
		return
	evening.advance(delta)
	if evening.busy:
		return
	if Input.is_action_just_pressed("interact"):
		evening.interact()
	elif Input.is_action_just_pressed("bed"):
		evening.sleep()


func _continue_after_unload() -> void:
	if run.done and not groceries.started:
		groceries.start()


func _continue_after_groceries() -> void:
	if groceries.done and not evening.started:
		evening.start(run.bad_day)


func _remember_at_bed() -> void:
	if not evening.asleep or _remembered:
		return
	var error := _memory.remember_day(evening.bad_day, evening.broom_skipped)
	if error != OK:
		push_error("Bed could not remember the day: %s" % error_string(error))
		return
	_remembered = true


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
