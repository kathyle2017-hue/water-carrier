extends Node2D

signal completed(bad_day: bool)

const SchoolRules = preload("res://scripts/school_state.gd")
const BODY = preload("res://assets/water_carrier.png")
var father_home := true
var start_in_class := false
var state := SchoolRules.new()
var _sent := false
var _walk_time := 0.0
var _carrier: Sprite2D
var _prompt: Label
var _feeling: Label

func _ready() -> void:
	_carrier = Sprite2D.new()
	_carrier.name = "WaterCarrier"
	_carrier.texture = BODY
	_carrier.hframes = 3
	_carrier.vframes = 4
	_carrier.offset = Vector2(0, -8)
	_carrier.position = Vector2(256, 112) if start_in_class else Vector2(48, 112)
	add_child(_carrier)
	_label("Huế · Huỳnh Thúc Kháng · School", Vector2(8, 5), Vector2(304, 16))
	_label("Home", Vector2(30, 66), Vector2(60, 16))
	_label("Class", Vector2(240, 61), Vector2(60, 16))
	_prompt = _label("", Vector2(8, 139), Vector2(304, 14))
	_feeling = _label("", Vector2(8, 154), Vector2(304, 26))
	_feeling.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state.changed.connect(_refresh)
	_refresh()

func _physics_process(delta: float) -> void:
	if _sent:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_carrier.position += direction * 65.0 * delta
	_carrier.position = _carrier.position.clamp(Vector2(20, 100), Vector2(300, 130))
	_walk_time += delta * 10.0
	var row := 0
	if absf(direction.x) > absf(direction.y):
		row = 1 if direction.x < 0 else 2
	elif direction.y < 0:
		row = 3
	_carrier.frame_coords = Vector2i(1 + int(_walk_time) % 2 if direction.length() > 0 else 0, row)
	state.set_at_class(_carrier.position.distance_to(Vector2(256, 112)) < 22)
	state.set_at_home(_carrier.position.distance_to(Vector2(48, 112)) < 22)
	if Input.is_action_just_pressed("interact"):
		state.interact()
	if state.done:
		_sent = true
		completed.emit(state.bad_day)

func _refresh() -> void:
	_prompt.text = state.prompt
	_feeling.text = state.feeling

func _label(text: String, where: Vector2, size: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = where
	label.size = size
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("382b27"))
	add_child(label)
	return label

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color("a9b684"))
	for x in range(0, 320, 16):
		for y in range(96, 144, 16):
			draw_rect(Rect2(x, y, 16, 16), Color("cbb88d") if (x + y) % 32 else Color("c0ad87"))
	draw_rect(Rect2(0, 137, 320, 43), Color("eee0b5"))
	_building(Vector2(24, 46), Vector2(64, 50))
	# Open classroom frontage: the playable lesson position is inside its floor.
	_building(Vector2(214, 40), Vector2(84, 34))
	draw_rect(Rect2(214, 82, 84, 52), Color("cdb087"))
	for y in range(82, 134, 16):
		draw_line(Vector2(214, y), Vector2(298, y), Color("bca17b"))
	draw_rect(Rect2(222, 66, 31, 9), Color("68795c"))
	draw_rect(Rect2(246, 92, 20, 15), Color("735c45"))
	draw_rect(Rect2(249, 92, 13, 3), Color("f2e5bc"))
	draw_rect(Rect2(274, 93, 15, 13), Color("987651"))
	for puddle in [Vector2(108, 119), Vector2(171, 108)]:
		draw_rect(Rect2(puddle, Vector2(23, 3)), Color("9baca1"))

func _building(at: Vector2, size: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(0, 10), size), Color("dfc492"))
	draw_colored_polygon(PackedVector2Array([at, at + Vector2(size.x, 0), at + Vector2(size.x + 6, 12), at + Vector2(-6, 12)]), Color("b47a54"))
	draw_rect(Rect2(at + Vector2(0, size.y), Vector2(size.x, 8)), Color("a88660"))
