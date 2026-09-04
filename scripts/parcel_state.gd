class_name ParcelState
extends RefCounted

## A food parcel's cook, outward walk, Handoff, and lighter walk home.
signal changed

enum Phase { NOT_STARTED, COOK, COOKING, OUTWARD, HANDOFF, HOMEWARD, DONE }
var _phase := Phase.NOT_STARTED
var _time := 0.0
var _at_gate := false
var feeling := ""
var loaded: bool:
	get: return _phase == Phase.OUTWARD
var done: bool:
	get: return _phase == Phase.DONE
var prompt: String:
	get:
		match _phase:
			Phase.COOK: return "E  Cook the parcel"
			Phase.COOKING: return "Cook · stir · wrap"
			Phase.OUTWARD: return "E  Handoff" if _at_gate else "Walk with Mother to Ái Thu"
			Phase.HANDOFF: return "Handoff"
			Phase.HOMEWARD: return "Walk home with Mother"
		return "Home for evening"

func start(cook_first := true) -> void:
	if _phase != Phase.NOT_STARTED:
		return
	_phase = Phase.COOK if cook_first else Phase.OUTWARD
	feeling = "Mother: Let us wrap the food while it is warm."
	changed.emit()

func movement_speed() -> float:
	return 42.0 if loaded else 62.0 if _phase == Phase.HOMEWARD else 0.0

func interact() -> bool:
	if _phase == Phase.COOK:
		_phase = Phase.COOKING
		_time = 1.8
		feeling = "Rice, greens, a warm pot. Mother holds the wrapping."
		changed.emit()
		return true
	if loaded and _at_gate:
		_phase = Phase.HANDOFF
		_time = 1.5
		feeling = "The food passes over. A quiet moment. Then turn home."
		changed.emit()
		return true
	return false

func advance(delta: float) -> void:
	if _phase == Phase.COOKING:
		_time -= delta
		if _time <= 0.0:
			_phase = Phase.OUTWARD
			feeling = "The food bags pull at her hands. Mother walks beside her."
			changed.emit()

	elif _phase == Phase.HANDOFF:
		_time -= delta
		if _time <= 0.0:
			_phase = Phase.HOMEWARD
			feeling = "Mother: We will be home before the evening bowl."
			changed.emit()

func enter_gate(inside: bool) -> void:
	if _at_gate != inside:
		_at_gate = inside
		changed.emit()

func enter_household(inside: bool) -> void:
	if inside and _phase == Phase.HOMEWARD:
		_phase = Phase.DONE
		feeling = "The bags are light. The household is waiting."
		changed.emit()
