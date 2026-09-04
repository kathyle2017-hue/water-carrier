extends Node2D

@onready var world: Node2D = $World
@onready var carrier: CharacterBody2D = $WaterCarrier
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
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


func _connect_zones() -> void:
	var fill: Area2D = world.get_node("FillZone")
	var unload: Area2D = world.get_node("UnloadZone")
	fill.body_entered.connect(func(body):
		if body == carrier:
			carrier.enter_fill(true)
	)
	fill.body_exited.connect(func(body):
		if body == carrier:
			carrier.enter_fill(false)
	)
	unload.body_entered.connect(func(body):
		if body == carrier:
			carrier.enter_unload(true)
	)
	unload.body_exited.connect(func(body):
		if body == carrier:
			carrier.enter_unload(false)
	)
