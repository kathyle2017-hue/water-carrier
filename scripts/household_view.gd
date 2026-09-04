extends Node2D

var father_home := false
var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	# Low table in the same slight-angle view as the road.
	draw_rect(Rect2(-20, -4, 45, 18), Color("936444"))
	draw_rect(Rect2(-20, -4, 45, 4), Color("c49361"))
	_person(Vector2(-25, -12), Color("88719a")) # Mother
	_person(Vector2(24, 18), Color("bd815b")) # Sister
	for x in [-10, 12]:
		draw_circle(Vector2(x, 3), 4, Color("e6d3a1"))
	if father_home:
		_person(Vector2(25, -13), Color("6c786a"))
		var fan_center := Vector2(-12, -18 + sin(_time * 5.0) * 3)
		draw_colored_polygon(PackedVector2Array([fan_center, fan_center + Vector2(4, -9), fan_center + Vector2(13, -6), fan_center + Vector2(11, 2)]), Color("d9b56d"))
		for line in 3:
			draw_line(fan_center, fan_center + Vector2(5 + line * 3, -7), Color("9d7c45"))

func _person(at: Vector2, cloth: Color) -> void:
	draw_ellipse_shadow(at)
	draw_rect(Rect2(at + Vector2(-5, -12), Vector2(10, 14)), cloth)
	draw_rect(Rect2(at + Vector2(-4, -20), Vector2(8, 8)), Color("c88e60"))
	draw_rect(Rect2(at + Vector2(-4, -22), Vector2(8, 4)), Color("49362f"))

func draw_ellipse_shadow(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-6, 1), Vector2(12, 3)), Color(0.25, 0.2, 0.12, 0.2))
