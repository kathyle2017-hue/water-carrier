class_name EveningState
extends RefCounted

## One Evening at the household. Talk and Pot lead to the choice to complete
## the night must, Broom, before Bed.
signal changed

enum Phase {
	NOT_STARTED,
	TALK_READY,
	TALKING,
	POT_READY,
	COOKING,
	EVENING_CHOICE,
	SWEEPING,
	BED_READY,
	ASLEEP,
}

var _phase := Phase.NOT_STARTED
var _busy_time := 0.0
var _bad_day := false
var _feeling := ""
var _notice := ""
var _pot_step := 0
var _broom_done := false
var _broom_skipped := false

var started: bool:
	get: return _phase != Phase.NOT_STARTED
var talking: bool:
	get: return _phase == Phase.TALKING
var cooking: bool:
	get: return _phase == Phase.COOKING
var sweeping: bool:
	get: return _phase == Phase.SWEEPING
var busy: bool:
	get: return talking or cooking or sweeping
var bad_day: bool:
	get: return _bad_day
var broom_done: bool:
	get: return _broom_done
var broom_skipped: bool:
	get: return _broom_skipped
var asleep: bool:
	get: return _phase == Phase.ASLEEP
var feeling: String:
	get: return _feeling
var notice: String:
	get: return _notice
var prompt: String:
	get:
		if _phase == Phase.TALK_READY:
			return "E  Talk"
		if talking:
			return "Talk"
		if _phase == Phase.POT_READY:
			return "E  Pot"
		if cooking:
			return "Pot"
		if _phase == Phase.EVENING_CHOICE:
			return "E  Broom    B  Bed"
		if sweeping:
			return "Broom"
		if _phase == Phase.BED_READY:
			return "B  Bed"
		return ""


func start(day_was_bad: bool) -> void:
	if _phase != Phase.NOT_STARTED:
		return
	_bad_day = day_was_bad
	_phase = Phase.TALK_READY
	changed.emit()


func interact() -> bool:
	if _phase == Phase.TALK_READY:
		_phase = Phase.TALKING
		_busy_time = 1.2
		_feeling = "Mother sees the day in her shoulders. Sister makes room at the bowl." if bad_day else "Mother: The rain let you home. Sister: Eat while it is warm."
	elif _phase == Phase.POT_READY:
		_phase = Phase.COOKING
		_busy_time = 0.5
		_pot_step = 0
		_feeling = "Chop."
	elif _phase == Phase.EVENING_CHOICE:
		_phase = Phase.SWEEPING
		_busy_time = 1.3
		_feeling = "Leaves gather dark in the yard. She sweeps them clear."
	else:
		return false
	changed.emit()
	return true


func advance(delta: float) -> void:
	if not busy:
		return
	_busy_time -= delta
	if _busy_time > 0.0:
		return
	while _busy_time <= 0.0 and busy:
		if talking:
			_phase = Phase.POT_READY
		elif cooking:
			_pot_step += 1
			if _pot_step == 1:
				_feeling = "Stir."
			elif _pot_step == 2:
				_feeling = "Serve the bowl."
			else:
				_phase = Phase.EVENING_CHOICE
		elif sweeping:
			_phase = Phase.BED_READY
			_broom_done = true
			_feeling = "The yard is quiet. The household can sleep."
		_busy_time += 0.5
	changed.emit()


func sleep() -> bool:
	if _phase != Phase.EVENING_CHOICE and _phase != Phase.BED_READY:
		return false
	_broom_skipped = not broom_done
	if broom_skipped:
		_bad_day = true
		_notice = "The game remembers. The household will feel the unswept yard in the morning."
	elif bad_day:
		_notice = "The game remembers the hard day."
	else:
		_notice = "The game remembers this day."
	_phase = Phase.ASLEEP
	_feeling = "Bed. Rain settles over Huế."
	changed.emit()
	return true
