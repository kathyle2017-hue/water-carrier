extends Node2D

## The chapter host enters after Unload and receives the shift outcome for Evening.
signal completed(bad_day: bool)

@export var rainy := true
var state = preload("res://scripts/quan_state.gd").new()
var _reported := false
var _clock := 0.0
var _facing := 2
var _moving := false
var _carrier := preload("res://assets/water_carrier.png")
var _ink := Color("49372f")
var _cream := Color("fae6b7")
var _font: Font

func _ready() -> void:
	_font = ThemeDB.fallback_font
	state.start(rainy)

func _physics_process(delta: float) -> void:
	_clock += delta
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_moving = direction.length() > 0.1
	if _moving:
		if absf(direction.x) > absf(direction.y):
			_facing = 1 if direction.x < 0 else 2
		else:
			_facing = 3 if direction.y < 0 else 0
	state.advance(delta)
	state.move(direction, delta, Input.is_action_pressed("hurry"))
	if Input.is_action_just_pressed("interact"):
		state.interact()
	queue_redraw()
	if state.done and not _reported:
		_reported = true
		completed.emit(state.bad_day)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color("9fae77"))
	if state.cycling:
		_draw_ride()
	else:
		_draw_cafe()
	_draw_carrier()
	if rainy and state.cycling:
		for drop in range(28):
			var x := fmod(drop * 37 + _clock * 28, 320)
			var y := fmod(drop * 23 + _clock * 75, 154)
			draw_line(Vector2(x, y), Vector2(x - 2, y + 5), Color("d6dbbb"))
	draw_rect(Rect2(0, 0, 320, 29), _ink)
	_text(Vector2(7, 12), state.place_name(), _cream, 10)
	var status: String = "Grip %s%%" % int(state.grip * 100) if state.cycling else "Served %s/4 · %ss" % [state.served, ceili(state.time_left)]
	_text(Vector2(7, 24), status, _cream)
	draw_rect(Rect2(0, 155, 320, 25), _ink)
	_text(Vector2(5, 165), state.prompt, _cream)
	_text(Vector2(5, 176), state.notice, _cream, 7)

func _draw_ride() -> void:
	if state.on_bridge:
		draw_rect(Rect2(0, 30, 320, 125), Color("719c91"))
		for x in range(0, 320, 16):
			draw_line(Vector2(x, 64), Vector2(x + 9, 64), Color("b9c5a0"))
		draw_rect(Rect2(0, 86, 320, 55), Color("b9ac87"))
		for x in range(0, 320, 32):
			draw_line(Vector2(x, 81), Vector2(x, 93), _ink, 2)
			draw_line(Vector2(x, 138), Vector2(x, 146), _ink, 2)
		draw_line(Vector2(0, 82), Vector2(320, 82), _cream, 2)
		draw_line(Vector2(0, 139), Vector2(320, 139), _cream, 2)
	else:
		for x in range(0, 320, 64):
			draw_rect(Rect2(x + 4, 43, 48, 40), Color("ceac79"))
			draw_rect(Rect2(x + 1, 39, 54, 10), Color("aa7354"))
			draw_rect(Rect2(x + 18, 61, 13, 22), _ink)
		draw_rect(Rect2(0, 86, 320, 58), Color("c3b28a"))
		if state.at_thong_hoi:
			_text(Vector2(230, 58), "Quán →", _ink, 10)
	if rainy:
		for x in range(28, 320, 67):
			draw_rect(Rect2(x, 126, 27, 4), Color("98b4a1"))

func _draw_cafe() -> void:
	# Wall height, visible table fronts, and short shadows keep the shared slight 3/4 view.
	draw_rect(Rect2(8, 34, 211, 117), Color("d2b082"))
	draw_rect(Rect2(8, 34, 211, 20), Color("e8cfa1"))
	for x in range(8, 220, 16):
		draw_line(Vector2(x, 55), Vector2(x, 150), Color("c4a175"))
	draw_rect(Rect2(224, 57, 88, 96), Color("b1b681"))
	_text(Vector2(236, 70), "Outside", _ink)
	draw_rect(Rect2(19, 48, 43, 12), Color("9c6648"))
	draw_rect(Rect2(19, 60, 43, 6), Color("704b38"))
	_text(Vector2(20, 45), "Counter", _ink)
	for table in range(state.table_positions.size()):
		var point: Vector2 = state.table_positions[table]
		draw_rect(Rect2(point + Vector2(-15, -12), Vector2(30, 16)), Color("aa7850"))
		draw_rect(Rect2(point + Vector2(-15, 4), Vector2(30, 5)), Color("80583b"))
		draw_rect(Rect2(point + Vector2(14, -10), Vector2(7, 7)), Color("d9ad83"))
		draw_rect(Rect2(point + Vector2(13, -3), Vector2(10, 9)), Color("7f9578"))
		_text(point + Vector2(-12, -16), "%s %s" % [table + 1, state.table_status(table)], _ink, 7)
		if state.table_status(table) == "served":
			draw_rect(Rect2(point + Vector2(-3, -7), Vector2(5, 5)), _cream)
	_text(Vector2(267, 148), "Home →", _ink)

func _draw_carrier() -> void:
	var point: Vector2 = state.position.round()
	var frame := 1 + int(fmod(_clock * 8, 2)) if _moving else 0
	# Existing art uses 16 by 28 cells, shared with the water run.
	draw_texture_rect_region(_carrier, Rect2(point + Vector2(-8, -28), Vector2(16, 28)), Rect2(frame * 16, _facing * 28, 16, 28))
	if state.cycling:
		for offset in [-8, 8]:
			draw_circle(point + Vector2(offset, -1), 4, _ink, false, 1)
		draw_line(point + Vector2(-8, -1), point + Vector2(3, -9), Color("73584b"), 2)
		draw_line(point + Vector2(3, -9), point + Vector2(8, -1), Color("73584b"), 2)
	elif state.carrying >= 0:
		draw_rect(Rect2(point + Vector2(6, -11), Vector2(8, 2)), _ink)
		draw_rect(Rect2(point + Vector2(8, -15), Vector2(4, 4)), _cream)

func _text(at: Vector2, value: String, color: Color, size := 8) -> void:
	draw_string(_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
