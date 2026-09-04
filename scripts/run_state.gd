class_name WaterRunState
extends RefCounted

## One Water run. Callers report interaction, time, and Glass; this module owns
## eligibility, load, balance, and Bad day. Notifications expose finished changes.
signal changed

enum Phase { LIGHT, FILLING, LOADED, UNLOADING, DONE }

const LIGHT_SPEED := 58.0
const LOADED_SPEED := 30.0
const HURRY_SPEED := 46.0
const HURT_SPEED := 18.0
const LEAN_SPILL := 1.0

var _phase := Phase.LIGHT
var _busy_time := 0.0
var _hurt_time := 0.0
var _in_fill := false
var _in_unload := false
var _felt_the_stream := false
var _bad_day := false
var _lean := 0.0
var _lean_drift := 0.0
var _feeling := ""
var _notice := ""
var _place_name := "Huỳnh Thúc Kháng"

var loaded: bool:
	get: return _phase == Phase.LOADED or _phase == Phase.UNLOADING
var filling: bool:
	get: return _phase == Phase.FILLING
var unloading: bool:
	get: return _phase == Phase.UNLOADING
var busy: bool:
	get: return filling or unloading
var done: bool:
	get: return _phase == Phase.DONE
var bad_day: bool:
	get: return _bad_day
var lean: float:
	get: return _lean
var feeling: String:
	get: return _feeling
var notice: String:
	get: return _notice
var place_name: String:
	get: return _place_name
var prompt: String:
	get:
		if filling:
			return "Fill"
		if unloading:
			return "Unload"
		if _can_fill():
			return "E  Fill"
		if _can_unload():
			return "E  Unload"
		return "Shift  hurry" if loaded else ""


func _init(previous_broom_was_skipped := false) -> void:
	if previous_broom_was_skipped:
		_bad_day = true
		_feeling = "Morning begins with yesterday's Broom undone."
		_notice = "Leaves from last night still cling to the yard. Mother looks once."


func interact() -> bool:
	if _can_fill():
		_phase = Phase.FILLING
		_busy_time = 1.7
		_feeling = "Glass in the water. Leeches. She still fills."
	elif _can_unload():
		_phase = Phase.UNLOADING
		_busy_time = 1.3
	else:
		return false
	changed.emit()
	return true


func advance(delta: float, input: Vector2, hurry: bool) -> void:
	if busy:
		_busy_time -= delta
		if _busy_time <= 0.0:
			if filling:
				_phase = Phase.LOADED
				_feeling = "The đòn gánh is heavy on both shoulders."
			else:
				_phase = Phase.DONE
				_lean = 0.0
				_lean_drift = 0.0
				_feeling = "Clean water is home."
				_notice = "The household has water." if not bad_day else "The household has water. They will feel the day."
			changed.emit()
		return
	_hurt_time = maxf(0.0, _hurt_time - delta)
	if loaded:
		_update_lean(delta, input, hurry)
		changed.emit()


func movement_speed(hurry: bool) -> float:
	if busy or done:
		return 0.0
	var speed := LIGHT_SPEED
	if loaded:
		speed = HURRY_SPEED if hurry else LOADED_SPEED
	return minf(speed, HURT_SPEED) if _hurt_time > 0.0 else speed


func step_on_glass() -> void:
	_hurt_time = 1.4
	_bad_day = true
	if loaded:
		_lean = clampf(_lean + signf(_lean + 0.001) * 0.45, -1.35, 1.35)
		_notice = "Glass. Barefoot. The walk is slower."
		if absf(_lean) >= LEAN_SPILL:
			_spill()
	else:
		_notice = "Glass. Barefoot."
	_feeling = "Glass. She sees it now."
	changed.emit()


func enter_fill(inside: bool) -> void:
	_in_fill = inside
	if inside and not _felt_the_stream:
		_felt_the_stream = true
		_feeling = "Glass in the water. Leeches. She still fills."
	changed.emit()


func enter_unload(inside: bool) -> void:
	_in_unload = inside
	changed.emit()


func set_place(value: String) -> void:
	if _place_name == value:
		return
	_place_name = value
	changed.emit()


func _can_fill() -> bool:
	return _in_fill and _phase == Phase.LIGHT


func _can_unload() -> bool:
	return _in_unload and _phase == Phase.LOADED


func _update_lean(delta: float, input: Vector2, hurry: bool) -> void:
	# Both shoulders: the pole drifts; weaving and hurrying feed it.
	var wander := 0.55 if hurry else 0.22
	_lean_drift += randf_range(-wander, wander) * delta * 8.0
	_lean_drift = clampf(_lean_drift, -0.9, 0.9)
	var next := _lean + _lean_drift * delta + input.x * 0.55 * delta
	if input.length() < 0.1:
		next = lerp(next, 0.0, 2.4 * delta)
		_lean_drift = lerp(_lean_drift, 0.0, 2.4 * delta)
	_lean = clampf(next, -1.35, 1.35)
	if absf(_lean) >= LEAN_SPILL:
		_spill()


func _spill() -> void:
	_phase = Phase.LIGHT
	_lean = 0.0
	_lean_drift = 0.0
	_bad_day = true
	_notice = "The water is gone. She still has to Fill."
	_feeling = "The jugs are empty. No game-over. Walk back."
