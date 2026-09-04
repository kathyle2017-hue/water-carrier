extends Node2D

## Standalone parcel road; the day host supplies water beforehand and evening after.
signal completed(bad_day: bool)

const State = preload("res://scripts/parcel_state.gd")
const BODY = preload("res://assets/water_carrier.png")
@export var cook_first := true
var state = State.new()
var _player: Sprite2D
var _mother: Sprite2D
var _camera: Camera2D
var _title: Label
var _words: Label
var _finished := false
var _walk_time := 0.0
var _talked := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_player = _person("WaterCarrier", Vector2(64, 140), Color.WHITE)
	_mother = _person("Mother", Vector2(46, 153), Color(0.76, 0.84, 0.68))
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_right = 1056
	_camera.limit_top = 0
	_camera.limit_bottom = 240
	_camera.position_smoothing_enabled = false
	_player.add_child(_camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var backing := ColorRect.new()
	backing.color = Color(0.19, 0.23, 0.18, 0.94)
	backing.position = Vector2(0, 0)
	backing.size = Vector2(320, 46)
	canvas.add_child(backing)
	_title = _label(canvas, Vector2(6, 3), 11)
	_words = _label(canvas, Vector2(6, 19), 9)
	var controls := _label(canvas, Vector2(6, 164), 9)
	controls.text = "WASD / arrows  Walk     E / Space  Act"
	controls.add_theme_color_override("font_shadow_color", Color("403c2f"))
	controls.add_theme_constant_override("shadow_offset_x", 1)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	state.changed.connect(_refresh)
	state.start(cook_first)
	_refresh()

func _person(person_name: String, at: Vector2, tint: Color) -> Sprite2D:
	var person := Sprite2D.new()
	person.name = person_name
	person.texture = BODY
	person.hframes = 3
	person.vframes = 4
	person.offset = Vector2(0, -8)
	person.position = at
	person.modulate = tint
	person.z_index = 10
	add_child(person)
	return person

func _label(parent: Node, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = Vector2(308, 25)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f4e7c3"))
	parent.add_child(label)
	return label

func _physics_process(delta: float) -> void:
	state.enter_gate(_player.position.x >= 932.0)
	if Input.is_action_just_pressed("interact"):
		state.interact()
	state.advance(delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var step: Vector2 = direction * state.movement_speed() * delta
	_player.position += step
	_player.position.x = clampf(_player.position.x, 48, 960)
	_player.position.y = clampf(_player.position.y, 106, 170)
	if step.length() > 0.0:
		_walk_time += delta * 8.0
		var row := 2 if direction.x > 0.0 else 1
		if absf(direction.y) > absf(direction.x):
			row = 0 if direction.y > 0.0 else 3
		_player.frame_coords = Vector2i(1 + int(_walk_time) % 2, row)
		var companion := _player.position - Vector2(18, -13)
		_mother.position = _mother.position.move_toward(companion, state.movement_speed() * delta)
		_mother.frame_coords = _player.frame_coords
	else:
		_player.frame_coords.x = 0
		_mother.frame_coords.x = 0
	if not _talked and _player.position.x > 460:
		_talked = true
		state.feeling = "Mother: The greens were good today. He will know we chose them."
		_refresh()
	state.enter_household(_player.position.x <= 80)
	if state.done and not _finished:
		_finished = true
		completed.emit(false)
	queue_redraw()

func _refresh() -> void:
	_title.text = "Ái Thu · " + state.prompt
	_words.text = state.feeling

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1056, 240), Color("8f9b65"))
	for x in range(0, 1056, 16):
		for y in range(96, 192, 16):
			var color := Color("baa477") if (x / 16 + y / 16) % 3 else Color("c3ae82")
			draw_rect(Rect2(x, y, 16, 16), color)
	for x in range(160, 900, 128):
		draw_rect(Rect2(x, 69, 5, 29), Color("796345"))
		draw_rect(Rect2(x - 12, 52, 29, 25), Color("647d50"))
		draw_rect(Rect2(x + 50, 197, 26, 13), Color("768b58"))
	# Household and cooking pot at the start; only the exterior of the Gate ahead.
	draw_rect(Rect2(16, 51, 84, 38), Color("ceb586"))
	draw_rect(Rect2(10, 43, 96, 17), Color("a16f52"))
	draw_rect(Rect2(44, 67, 20, 22), Color("775e45"))
	draw_rect(Rect2(73, 108, 14, 9), Color("745d49"))
	draw_rect(Rect2(75, 105, 10, 4), Color("a7a779"))
	draw_rect(Rect2(977, 40, 16, 150), Color("b8a079"))
	draw_rect(Rect2(919, 48, 74, 12), Color("927456"))
	draw_rect(Rect2(951, 73, 27, 20), Color("d9c295"))
	draw_rect(Rect2(954, 96, 22, 7), Color("806747"))
	if _player != null:
		# Hand-carried food bags, deliberately separate from the water-run rig.
		if state.loaded:
			for offset in [-10, 7]:
				draw_rect(Rect2(_player.position + Vector2(offset, -3), Vector2(6, 8)), Color("b78053"))
				draw_arc(_player.position + Vector2(offset + 3, -3), 2, PI, TAU, 6, Color("705d43"))
