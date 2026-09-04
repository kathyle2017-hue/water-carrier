extends Node2D

signal completed(bad_day: bool)

@export var finish_piece := false
@export var needs_repair := false

var state := SewingState.new()
var piece_finished: bool:
	get: return state.piece_finished
var _elapsed := 0.0
var _reported := false

@onready var _feeling: Label = $Feeling
@onready var _prompt: Label = $Prompt
@onready var _help: Label = $Help


func _ready() -> void:
	state.changed.connect(_refresh)
	state.start(finish_piece, needs_repair)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		state.interact()
	state.advance(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_X:
		state.skip()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	_feeling.text = state.feeling
	_prompt.text = state.prompt
	_help.text = "E / Space continues   X leaves sewing" if not state.done else "Sewing is over for today."
	if state.done and not _reported:
		_reported = true
		completed.emit(state.bad_day)
	queue_redraw()


func _draw() -> void:
	# The household shares the road's warm palette and slightly angled floor.
	draw_rect(Rect2(0, 0, 320, 180), Color("ead4a4"))
	draw_rect(Rect2(0, 30, 320, 92), Color("83986a"))
	draw_rect(Rect2(23, 37, 276, 73), Color("bb9060"))
	draw_rect(Rect2(30, 40, 262, 34), Color("d9b77d"))
	draw_colored_polygon(PackedVector2Array([Vector2(30, 74), Vector2(292, 74), Vector2(306, 119), Vector2(15, 119)]), Color("b18558"))
	for row in range(3):
		draw_line(Vector2(26 - row * 3, 84 + row * 12), Vector2(296 + row * 3, 84 + row * 12), Color("99714b"))
	for column in range(8):
		var x := 32 + column * 36
		draw_line(Vector2(x, 75), Vector2(x - 12, 119), Color("a57850"))
	# Daylight and rain beyond the window, never a grey chapter grade.
	draw_rect(Rect2(141, 42, 44, 29), Color("705b45"))
	draw_rect(Rect2(144, 44, 38, 24), Color("9cab79"))
	for drop in range(7):
		var y := 45 + int(_elapsed * 18 + drop * 9) % 20
		draw_line(Vector2(146 + drop * 5, y), Vector2(145 + drop * 5, y + 3), Color("d4d6a6"))
	draw_rect(Rect2(161, 42, 2, 29), Color("705b45"))
	# Mother and the water-carrier are seated at the same piece. Neither has a yoke.
	_draw_sewer(Vector2(104, 75), Color("a26f63"), true)
	_draw_sewer(Vector2(218, 76), Color("536e70"), false)
	# This broad length and fringed ends read as export carpet work, never clothes.
	var length := 174.0 if state.unrolled else 60.0
	var left := (320.0 - length) / 2.0
	draw_rect(Rect2(left + 2, 89, length, 25), Color("71523e"))
	draw_rect(Rect2(left, 86, length, 24), Color("b66750"))
	draw_rect(Rect2(left + 4, 90, length - 8, 16), Color("d8b878"))
	draw_rect(Rect2(left + 7, 93, length - 14, 10), Color("747f59"))
	for stitch in range(int(length / 12)):
		var x := left + 10 + stitch * 12
		draw_rect(Rect2(x, 95, 4, 5), Color("e8ca91"))
	for fringe in range(7):
		draw_line(Vector2(left - 3, 87 + fringe * 3), Vector2(left, 87 + fringe * 3), Color("eee0b0"))
		draw_line(Vector2(left + length, 87 + fringe * 3), Vector2(left + length + 3, 87 + fringe * 3), Color("eee0b0"))
	# A spool and thread follow Mother's hand as she sews in view.
	draw_rect(Rect2(56, 78, 6, 8), Color("eee0b0"))
	draw_rect(Rect2(55, 78, 8, 2), Color("805c44"))
	draw_line(Vector2(62, 82), Vector2(112, 82 + int(sin(_elapsed * 4) * 2)), Color("eee0b0"))
	if state.working:
		draw_line(Vector2(208, 85), Vector2(205, 96), Color("eee0b0"))
	draw_rect(Rect2(0, 123, 320, 57), Color("ead4a4"))


func _draw_sewer(at: Vector2, clothing: Color, mother: bool) -> void:
	var stitch_motion := int(sin(_elapsed * 4) * 2) if mother or state.working else 0
	draw_rect(Rect2(at + Vector2(-9, 7), Vector2(19, 6)), Color("765443"))
	draw_rect(Rect2(at + Vector2(-6, -4), Vector2(12, 12)), clothing)
	draw_rect(Rect2(at + Vector2(-5, -14), Vector2(10, 10)), Color("483e33"))
	draw_rect(Rect2(at + Vector2(-4, -10), Vector2(8, 7)), Color("d5a36c"))
	draw_rect(Rect2(at + Vector2(1, -8), Vector2(1, 1)), Color("483e33"))
	draw_rect(Rect2(at + Vector2(-8, 1), Vector2(4, 7)), clothing)
	draw_rect(Rect2(at + Vector2(5, 1), Vector2(4, 7)), clothing)
	draw_rect(Rect2(at + Vector2(7, 7 + stitch_motion), Vector2(4, 3)), Color("d5a36c"))
	if mother:
		draw_rect(Rect2(at + Vector2(-7, -12), Vector2(4, 5)), Color("483e33"))
		draw_rect(Rect2(at + Vector2(-3, 0), Vector2(6, 9)), Color("d5c697"))
	else:
		draw_rect(Rect2(at + Vector2(-6, -10), Vector2(3, 12)), Color("483e33"))
