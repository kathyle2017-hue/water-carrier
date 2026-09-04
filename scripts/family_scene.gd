extends Node2D

## Equal-sized, user-advanced scenes at either end of the Father's absence.
signal completed(bad_day: bool)

const BODY = preload("res://assets/water_carrier.png")
const CAPTURE_LINES: PackedStringArray = [
	"Đà Nẵng, 1975. She waits beside Mother, her bag at her feet.",
	"News reaches them: Father was captured at Thuận An while the family tried to leave. He is away.",
	"Back in Huế, class continues. His place at dinner is empty. They will carry food to him.",
]
const RETURN_LINES: PackedStringArray = [
	"Around 1988. The years turn. Father walks through the doorway; she looks up from the bowl.",
	"Mother fans his food. Mother: Here, let it cool. Sister: There is room beside us.",
	"Father: It is warm here. She moves his bowl closer. For a while, they sit together.",
]
@export var is_return := false
var _arrival_time := 0.0
var _father: Sprite2D
var _fan: Polygon2D
var _beat := 0
var _finished := false
var _talk: Label
var _prompt: Label

func _ready() -> void:
	_label("Place", "Huế · Return · around 1988" if is_return else "Đà Nẵng · 1975", Vector2(8, 6), Vector2(304, 16))
	_person("WaterCarrier", Vector2(170, 119) if is_return else Vector2(145, 103), Color.WHITE)
	var mother := _person("Mother", Vector2(127, 94) if is_return else Vector2(171, 101), Color("c79880"))
	if is_return:
		_person("Sister", Vector2(144, 118), Color("ccb584"))
		_father = _person("Father", Vector2(288, 96), Color("a5aca0"))
		_fan = Polygon2D.new()
		_fan.name = "Fan"
		_fan.position = Vector2(8, -4)
		_fan.polygon = PackedVector2Array([Vector2.ZERO, Vector2(3, -9), Vector2(10, -11), Vector2(13, -5), Vector2(5, 1)])
		_fan.color = Color("e4c778")
		_fan.visible = false
		mother.add_child(_fan)
	_talk = _label("Talk", "", Vector2(8, 139), Vector2(304, 30))
	_talk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt = _label("Prompt", "E  Continue", Vector2(8, 168), Vector2(304, 12))
	_refresh()

func _physics_process(delta: float) -> void:
	if _finished:
		return
	if is_return:
		_arrival_time += delta
		_father.position.x = move_toward(_father.position.x, 183.0, delta * 60.0)
		var arrived := is_equal_approx(_father.position.x, 183.0)
		_father.frame_coords = Vector2i(0, 0) if arrived else Vector2i(1 + int(_arrival_time * 9) % 2, 1)
		_fan.visible = arrived
		_fan.rotation = sin(_arrival_time * 4.0) * 0.35
		_prompt.text = "E  Continue" if arrived else "Father walks in."
		if not arrived:
			return
	if Input.is_action_just_pressed("interact"):
		_beat += 1
		if _beat == CAPTURE_LINES.size():
			_finished = true
			_prompt.text = ""
			completed.emit(false)
		else:
			_refresh()

func _refresh() -> void:
	_talk.text = RETURN_LINES[_beat] if is_return else CAPTURE_LINES[_beat]

func _person(person_name: String, where: Vector2, tint: Color) -> Sprite2D:
	var person := Sprite2D.new()
	person.name = person_name
	person.texture = BODY
	person.hframes = 3
	person.vframes = 4
	person.position = where
	person.offset = Vector2(0, -8)
	person.modulate = tint
	add_child(person)
	return person

func _label(label_name: String, text: String, where: Vector2, size: Vector2) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.position = where
	label.size = size
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("382b27"))
	add_child(label)
	return label

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color("b9bd94"))
	draw_rect(Rect2(0, 130, 320, 50), Color("eee0b5"))
	for x in range(16, 304, 16):
		for y in range(64, 128, 16):
			draw_rect(Rect2(x, y, 16, 16), Color("d1bd96") if (x + y) % 32 else Color("c5b18a"))
	draw_rect(Rect2(24, 34, 272, 38), Color("e0c9a0"))
	draw_colored_polygon(PackedVector2Array([Vector2(24, 30), Vector2(290, 30), Vector2(301, 43), Vector2(18, 43)]), Color("b67c58"))
	if is_return:
		draw_rect(Rect2(144, 84, 33, 22), Color("a78058"))
		draw_rect(Rect2(144, 84, 33, 17), Color("cba579"))
		draw_rect(Rect2(156, 88, 10, 5), Color("f3e6bd"))
		draw_rect(Rect2(158, 87, 6, 2), Color("739467"))
	else:
		draw_rect(Rect2(129, 106, 8, 6), Color("9b7050"))
