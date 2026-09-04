extends CharacterBody2D

const LIGHT_SPEED := 58.0
const LOADED_SPEED := 30.0
const HURRY_SPEED := 46.0
const HURT_SLOW := 18.0

@onready var sprite: Sprite2D = $Sprite
@onready var yoke: Sprite2D = $Yoke
@onready var jug_left: Sprite2D = $Yoke/JugLeft
@onready var jug_right: Sprite2D = $Yoke/JugRight
@onready var camera: Camera2D = $Camera2D

var _facing := Vector2.DOWN
var _walk_phase := 0.0
var _hurt_time := 0.0
var _busy_time := 0.0
var _in_fill := false
var _in_unload := false
var _in_stream := false
var _lean_drift := 0.0
var _base_sprite_y := 0.0


func _ready() -> void:
	_base_sprite_y = sprite.position.y
	_apply_jug_frames()
	yoke.visible = true


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


func _physics_process(delta: float) -> void:
	var world := get_parent().get_node_or_null("World")
	if world and world.has_method("place_at"):
		RunState.set_place(world.place_at(global_position.x))

	if _busy_time > 0.0:
		_busy_time -= delta
		velocity = Vector2.ZERO
		_animate_busy()
		move_and_slide()
		if _busy_time <= 0.0:
			_finish_busy()
		return

	if _hurt_time > 0.0:
		_hurt_time -= delta

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var hurry := Input.is_action_pressed("hurry") and RunState.loaded
	var speed := LIGHT_SPEED
	if RunState.loaded:
		speed = HURRY_SPEED if hurry else LOADED_SPEED
	if _hurt_time > 0.0:
		speed = minf(speed, HURT_SLOW)

	velocity = input * speed
	if input.length() > 0.15:
		_facing = input.normalized()
		_walk_phase += delta * (8.0 if RunState.loaded else 11.0)
	else:
		_walk_phase = 0.0

	if RunState.loaded:
		_update_lean(delta, input, hurry)
	else:
		RunState.reset_lean()
		_lean_drift = 0.0

	_update_prompt()
	_try_interact()
	_animate_walk()
	_update_yoke()
	move_and_slide()


func _update_lean(delta: float, input: Vector2, hurry: bool) -> void:
	# Both shoulders: the pole drifts; weaving and hurrying feed it.
	var wander := 0.55 if hurry else 0.22
	_lean_drift += randf_range(-wander, wander) * delta * 8.0
	_lean_drift = clampf(_lean_drift, -0.9, 0.9)
	var next := RunState.lean + _lean_drift * delta
	next += input.x * 0.55 * delta
	if input.length() < 0.1:
		next = lerp(next, 0.0, 2.4 * delta)
		_lean_drift = lerp(_lean_drift, 0.0, 2.4 * delta)
	RunState.set_lean(next)
	if absf(RunState.lean) >= RunState.LEAN_SPILL:
		_spill()


func _update_prompt() -> void:
	if RunState.filling or RunState.unloading:
		return
	if _in_fill and not RunState.loaded and not RunState.done:
		RunState.set_prompt("E  Fill")
	elif _in_unload and RunState.loaded:
		RunState.set_prompt("E  Unload")
	elif RunState.loaded:
		RunState.set_prompt("Shift  hurry")
	else:
		RunState.set_prompt("")


func _try_interact() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	if _in_fill and not RunState.loaded and not RunState.done and not RunState.filling:
		_start_fill()
	elif _in_unload and RunState.loaded and not RunState.unloading:
		_start_unload()


func _start_fill() -> void:
	RunState.filling = true
	RunState.set_prompt("Fill")
	RunState.set_feeling("Glass in the water. Leeches. She still fills.")
	_busy_time = 1.7


func _start_unload() -> void:
	RunState.unloading = true
	RunState.set_prompt("Unload")
	_busy_time = 1.3


func _animate_busy() -> void:
	if RunState.filling:
		# Wade: dip to the knees.
		sprite.position.y = _base_sprite_y + 5
		yoke.position.y = 2
	elif RunState.unloading:
		sprite.position.y = _base_sprite_y
		yoke.rotation = lerp_angle(yoke.rotation, 0.35, 0.08)


func _finish_busy() -> void:
	sprite.position.y = _base_sprite_y
	yoke.rotation = 0.0
	yoke.position.y = -10
	if RunState.filling:
		RunState.filling = false
		RunState.set_loaded(true)
		RunState.set_feeling("The đòn gánh is heavy on both shoulders.")
		RunState.set_prompt("")
		_apply_jug_frames()
	elif RunState.unloading:
		RunState.unloading = false
		RunState.set_loaded(false)
		RunState.done = true
		yoke.visible = false
		RunState.set_feeling("Clean water is home.")
		RunState.set_prompt("")
		RunState.notice = "The household has water." if not RunState.bad_day else "The household has water. They will feel the day."
		RunState.changed.emit()


func _spill() -> void:
	RunState.set_loaded(false)
	RunState.mark_bad_day("The water is gone. She still has to Fill.")
	RunState.set_feeling("The jugs are empty. No game-over. Walk back.")
	_apply_jug_frames()
	_lean_drift = 0.0
	RunState.reset_lean()


func step_on_glass() -> void:
	_hurt_time = 1.4
	if RunState.loaded:
		RunState.set_lean(RunState.lean + signf(RunState.lean + 0.001) * 0.45)
		RunState.mark_bad_day("Glass. Barefoot. The walk is slower.")
		if absf(RunState.lean) >= RunState.LEAN_SPILL:
			_spill()
	else:
		RunState.mark_bad_day("Glass. Barefoot.")
	RunState.set_feeling("Glass. She sees it now.")


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
	yoke.rotation = RunState.lean * 0.28
	jug_left.rotation = -yoke.rotation
	jug_right.rotation = -yoke.rotation
	if RunState.loaded:
		yoke.position.y = -10 + sin(_walk_phase * 0.9) * 1.2
	else:
		yoke.position.y = -10


func _apply_jug_frames() -> void:
	var frame := 1 if RunState.loaded else 0
	jug_left.frame = frame
	jug_right.frame = frame


func enter_fill(inside: bool) -> void:
	_in_fill = inside
	if inside and not RunState.felt_the_stream:
		RunState.felt_the_stream = true
		RunState.set_feeling("Glass in the water. Leeches. She still fills.")


func enter_unload(inside: bool) -> void:
	_in_unload = inside


func enter_stream(inside: bool) -> void:
	_in_stream = inside
