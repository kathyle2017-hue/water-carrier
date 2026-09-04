extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var yoke: Sprite2D = $Yoke
@onready var jug_left: Sprite2D = $Yoke/JugLeft
@onready var jug_right: Sprite2D = $Yoke/JugRight
@onready var camera: Camera2D = $Camera2D

var _facing := Vector2.DOWN
var _walk_phase := 0.0
var _run: WaterRunState
var _groceries: GroceriesState
var _base_sprite_y := 0.0


func _ready() -> void:
	_base_sprite_y = sprite.position.y


func setup_camera(map_size: Vector2) -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_size.x)
	camera.limit_bottom = int(map_size.y)
	camera.position_smoothing_enabled = false


func attach_rain(rain: CPUParticles2D) -> void:
	var parent := rain.get_parent()
	if parent:
		parent.remove_child(rain)
	camera.add_child(rain)
	rain.position = Vector2.ZERO


func setup(run: WaterRunState, groceries: GroceriesState) -> void:
	_run = run
	_groceries = groceries
	_run.changed.connect(_refresh_load)
	_refresh_load()


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var hurry := Input.is_action_pressed("hurry")
	var was_busy := _run.busy
	_run.advance(delta, input, hurry)
	if not was_busy and Input.is_action_just_pressed("interact"):
		_run.interact()
	var speed := _groceries.movement_speed() if _run.done else _run.movement_speed(hurry)
	velocity = Vector2.ZERO if was_busy else input * speed
	if input.length() > 0.15 and velocity.length() > 0.0:
		_facing = input.normalized()
		_walk_phase += delta * (8.0 if _run.loaded else 11.0)
	else:
		_walk_phase = 0.0
	if _run.busy:
		_animate_busy()
	else:
		_animate_walk()
		_update_yoke()
	move_and_slide()


func _animate_busy() -> void:
	if _run.filling:
		# Wade: dip to the knees.
		sprite.position.y = _base_sprite_y + 5
		yoke.position.y = 2
	elif _run.unloading:
		yoke.rotation = lerp_angle(yoke.rotation, 0.35, 0.08)


func _refresh_load() -> void:
	sprite.position.y = _base_sprite_y
	yoke.visible = not _run.done
	var frame := 1 if _run.loaded else 0
	jug_left.frame = frame
	jug_right.frame = frame


func step_on_glass() -> void:
	_run.step_on_glass()


func _animate_walk() -> void:
	var row := 0
	if absf(_facing.x) > absf(_facing.y):
		row = 1 if _facing.x < 0.0 else 2
	else:
		row = 0 if _facing.y > 0.0 else 3
	var frame := 0
	if velocity.length() > 4.0:
		frame = 1 + int(fmod(_walk_phase, 2.0))
	sprite.frame_coords = Vector2i(frame, row)


func _update_yoke() -> void:
	if not yoke.visible:
		return
	yoke.rotation = _run.lean * 0.28
	jug_left.rotation = -yoke.rotation
	jug_right.rotation = -yoke.rotation
	if _run.loaded:
		yoke.position.y = -10 + sin(_walk_phase * 0.9) * 1.2
	else:
		yoke.position.y = -10
