extends Node

## Shared state for the first water-run mock. Not a day loop yet.

signal changed

var loaded: bool = false
var filling: bool = false
var unloading: bool = false
var done: bool = false
var bad_day: bool = false
var felt_the_stream: bool = false
var lean: float = 0.0
var prompt: String = ""
var feeling: String = ""
var notice: String = ""
var place_name: String = "Huỳnh Thúc Kháng"

const LEAN_SPILL := 1.0


func reset_lean() -> void:
	if is_zero_approx(lean):
		return
	lean = 0.0
	emit_signal("changed")


func set_loaded(value: bool) -> void:
	loaded = value
	if not loaded:
		lean = 0.0
	emit_signal("changed")


func mark_bad_day(reason: String) -> void:
	bad_day = true
	notice = reason
	emit_signal("changed")


func set_prompt(value: String) -> void:
	if prompt == value:
		return
	prompt = value
	emit_signal("changed")


func set_feeling(value: String) -> void:
	feeling = value
	emit_signal("changed")


func set_place(value: String) -> void:
	if place_name == value:
		return
	place_name = value
	emit_signal("changed")


func set_lean(value: float) -> void:
	lean = clampf(value, -1.35, 1.35)
	emit_signal("changed")
