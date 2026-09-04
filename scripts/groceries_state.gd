class_name GroceriesState
extends RefCounted

## One Groceries trip after Unload. Callers report the Đông and household
## zones; this module owns the ordinary walk and short stall beat.
signal changed

enum Phase { NOT_STARTED, WALKING_TO_DONG, SHOPPING, WALKING_HOME, DONE }

const WALK_SPEED := 58.0

var _phase := Phase.NOT_STARTED
var _in_dong := false
var _busy_time := 0.0
var _stall_step := 0
var _feeling := ""
var _notice := ""

var started: bool:
	get: return _phase != Phase.NOT_STARTED
var shopping: bool:
	get: return _phase == Phase.SHOPPING
var busy: bool:
	get: return shopping
var done: bool:
	get: return _phase == Phase.DONE
var feeling: String:
	get: return _feeling
var notice: String:
	get: return _notice
var prompt: String:
	get:
		if _in_dong and _phase == Phase.WALKING_TO_DONG:
			return "E  Groceries"
		if _phase == Phase.WALKING_TO_DONG:
			return "Walk to Đông"
		if shopping:
			return "Groceries"
		if _phase == Phase.WALKING_HOME:
			return "Walk home"
		return ""


func start() -> void:
	if started:
		return
	_phase = Phase.WALKING_TO_DONG
	_feeling = "No đòn gánh. The walk is ordinary."
	changed.emit()


func movement_speed() -> float:
	return WALK_SPEED if _phase == Phase.WALKING_TO_DONG or _phase == Phase.WALKING_HOME else 0.0


func interact() -> bool:
	if not _in_dong or _phase != Phase.WALKING_TO_DONG:
		return false
	_phase = Phase.SHOPPING
	_busy_time = 0.5
	_stall_step = 0
	_feeling = "List: greens, rice, salt."
	changed.emit()
	return true


func advance(delta: float) -> void:
	if not busy:
		return
	_busy_time -= delta
	if _busy_time > 0.0:
		return
	while _busy_time <= 0.0 and busy:
		_stall_step += 1
		if _stall_step == 1:
			_feeling = "Pay or barter."
		elif _stall_step == 2:
			_feeling = "Bag."
		else:
			_phase = Phase.WALKING_HOME
			_feeling = "The bag is ready. Walk home."
		_busy_time += 0.5
	changed.emit()


func enter_dong(inside: bool) -> void:
	_in_dong = inside
	changed.emit()


func enter_household(inside: bool) -> void:
	if inside and _phase == Phase.WALKING_HOME:
		_phase = Phase.DONE
		_feeling = "The bag is set down beside the clean water."
		_notice = "Groceries are home."
	changed.emit()


func place_name() -> String:
	if _phase == Phase.WALKING_TO_DONG:
		return "Đông · Phú Bình" if _in_dong else "Huỳnh Thúc Kháng → Đông"
	if shopping:
		return "Đông · Phú Bình"
	if _phase == Phase.WALKING_HOME:
		return "Phú Bình → Household"
	return "Household"
