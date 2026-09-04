extends Node2D

signal completed(bad_day: bool)

@export var piece_repaired := false

var state = preload("res://scripts/evaluate_state.gd").new()
var needs_repair: bool:
	get: return state.needs_repair
var _reported := false
var _walk_time := 0.0
var _facing := Vector2.RIGHT
var _walking := false
const CARRIER := preload("res://assets/water_carrier.png")


func _ready() -> void:
	state.changed.connect(_refresh)
	state.start(piece_repaired)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var before: Vector2 = state.carrier_position
	state.move(direction, delta)
	_walking = before.distance_to(state.carrier_position) > 0.01
	if _walking:
		_facing = direction
		_walk_time += delta * 9.0
	if Input.is_action_just_pressed("interact"):
		state.interact()
	queue_redraw()


func _refresh() -> void:
	$Place.text = state.place
	$Feeling.text = state.feeling
	$Prompt.text = state.prompt
	if state.done and not _reported:
		_reported = true
		completed.emit(state.bad_day)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color("ead4a4"))
	var scroll := clampf(state.carrier_position.x - 160.0, 0.0, 320.0) if state.outside else 0.0
	draw_set_transform(Vector2(-scroll, 0))
	if state.outside:
		_draw_street()
	elif state.hall:
		_draw_hall()
	else:
		_draw_qa()
	_draw_carrier()
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0, 0, 320, 24), Color("ead4a4"))
	draw_rect(Rect2(0, 138, 320, 42), Color("ead4a4"))


func _draw_street() -> void:
	draw_rect(Rect2(0, 24, 640, 114), Color("a6af7c"))
	for house in range(7):
		var x := house * 72 + 8
		draw_rect(Rect2(x, 56, 52, 32), Color("cfb079"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 57), Vector2(x + 9, 39), Vector2(x + 47, 39), Vector2(x + 60, 57)]), Color("9f6c50"))
		draw_rect(Rect2(x + 20, 68, 12, 20), Color("756044"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 93), Vector2(640, 87), Vector2(640, 138), Vector2(0, 138)]), Color("bcab7c"))
	for stone in range(40):
		var x := stone * 16
		draw_line(Vector2(x, 94), Vector2(x - 6, 137), Color("af9d72"))
	for puddle in range(9):
		draw_rect(Rect2(85 + puddle * 53, 120 + puddle % 3 * 4, 21, 2), Color("a1b09a"))
	# One large building at the destination; the road is an authored approach.
	draw_rect(Rect2(514, 28, 116, 65), Color("dcc38d"))
	draw_rect(Rect2(507, 25, 126, 10), Color("986d4d"))
	for column in range(5):
		draw_rect(Rect2(521 + column * 21, 42, 12, 15), Color("84917a"))
		draw_rect(Rect2(521 + column * 21, 64, 12, 15), Color("84917a"))
	draw_rect(Rect2(579, 69, 26, 25), Color("706247"))
	draw_rect(Rect2(574, 92, 36, 6), Color("d4bd8c"))
	_draw_text(Vector2(539, 39), "Phú Hòa", 9)
	_draw_text(Vector2(18, 88), "Home", 8)


func _draw_hall() -> void:
	draw_rect(Rect2(4, 26, 312, 108), Color("b99463"))
	draw_rect(Rect2(8, 29, 304, 51), Color("dfc392"))
	draw_colored_polygon(PackedVector2Array([Vector2(8, 80), Vector2(312, 80), Vector2(320, 138), Vector2(0, 138)]), Color("bca575"))
	for row in range(4):
		draw_line(Vector2(4, 88 + row * 14), Vector2(316, 88 + row * 14), Color("a58b61"))
	for column in range(20):
		draw_line(Vector2(column * 16, 80), Vector2(column * 16 - 10, 138), Color("a58b61"))
	for door in range(4):
		var x := 32 + door * 76
		draw_rect(Rect2(x, 45, 28, 37), Color("9a754d"))
		draw_rect(Rect2(x + 3, 49, 22, 31), Color("77644b"))
		draw_rect(Rect2(x + 20, 67, 2, 2), Color("dfc785"))
		_draw_text(Vector2(x - 1, 41), ["Records", "Accounts", "Letters", "QA"][door], 7)
	# Ordinary people use other offices; none become playable companions.
	_draw_person(Vector2(90, 99), Color("9f7262"), false)
	_draw_person(Vector2(156, 108), Color("777f94"), false)
	_draw_person(Vector2(183, 103), Color("b98f63"), false)
	_draw_person(Vector2(234, 119), Color("839478"), false)
	draw_rect(Rect2(108, 114, 36, 8), Color("926945"))
	draw_rect(Rect2(112, 121, 3, 7), Color("795c40"))
	draw_rect(Rect2(137, 121, 3, 7), Color("795c40"))
	_draw_text(Vector2(12, 135), "Exit", 8)


func _draw_qa() -> void:
	draw_rect(Rect2(8, 28, 304, 54), Color("d6b987"))
	draw_colored_polygon(PackedVector2Array([Vector2(8, 82), Vector2(312, 82), Vector2(320, 138), Vector2(0, 138)]), Color("b9a173"))
	for row in range(4):
		draw_line(Vector2(4, 88 + row * 14), Vector2(316, 88 + row * 14), Color("a58b61"))
	draw_rect(Rect2(35, 40, 53, 27), Color("806a4f"))
	draw_rect(Rect2(38, 43, 47, 21), Color("a3b18a"))
	_draw_text(Vector2(143, 43), "Military quality assurance", 9)
	_draw_person(Vector2(211, 77), Color("74805b"), true)
	_draw_person(Vector2(263, 81), Color("74805b"), true)
	draw_rect(Rect2(171, 83, 112, 15), Color("a57951"))
	draw_rect(Rect2(171, 98, 112, 6), Color("8a6546"))
	draw_rect(Rect2(176, 103, 5, 9), Color("77583f"))
	draw_rect(Rect2(273, 103, 5, 9), Color("77583f"))
	# The long rectangular export work is inspected on the desk.
	draw_rect(Rect2(185, 84, 61, 10), Color("b66750"))
	draw_rect(Rect2(188, 86, 55, 6), Color("d8b878"))
	for stitch in range(8):
		draw_rect(Rect2(192 + stitch * 6, 88, 3, 2), Color("747f59"))
	draw_rect(Rect2(254, 85, 13, 9), Color("eee0b0"))


func _draw_person(at: Vector2, clothing: Color, military: bool) -> void:
	draw_rect(Rect2(at + Vector2(-6, -1), Vector2(14, 4)), Color("9c8b66"))
	draw_rect(Rect2(at + Vector2(-5, -15), Vector2(10, 12)), clothing)
	draw_rect(Rect2(at + Vector2(-4, -23), Vector2(8, 8)), Color("cea16f"))
	draw_rect(Rect2(at + Vector2(-4, -25), Vector2(8, 4)), clothing if military else Color("514433"))
	draw_rect(Rect2(at + Vector2(-4, -3), Vector2(3, 4)), Color("655b49"))
	draw_rect(Rect2(at + Vector2(2, -3), Vector2(3, 4)), Color("655b49"))


func _draw_carrier() -> void:
	var row := 0
	if absf(_facing.x) > absf(_facing.y):
		row = 1 if _facing.x < 0.0 else 2
	else:
		row = 0 if _facing.y > 0.0 else 3
	var frame := 1 + int(_walk_time) % 2 if _walking else 0
	var size := Vector2(CARRIER.get_width() / 3.0, CARRIER.get_height() / 4.0)
	var at: Vector2 = state.carrier_position.round()
	draw_texture_rect_region(CARRIER, Rect2(at - Vector2(size.x / 2.0, size.y - 5), size), Rect2(Vector2(frame, row) * size, size))
	if state.phase in [state.Phase.OUTWARD, state.Phase.HALL] or (needs_repair and state.phase in [state.Phase.LEAVE_HALL, state.Phase.HOMEWARD]):
		draw_rect(Rect2(at + Vector2(4, -10), Vector2(12, 7)), Color("b66750"))
		draw_rect(Rect2(at + Vector2(6, -8), Vector2(8, 3)), Color("d8b878"))


func _draw_text(at: Vector2, text: String, size: int) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("514433"))
