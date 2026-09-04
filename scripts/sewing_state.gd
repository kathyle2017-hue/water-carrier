class_name SewingState
extends RefCounted

## A daytime household must: unroll, share a section with Mother, then pack.
signal changed

enum Phase { NOT_STARTED, UNROLL_READY, UNROLLING, WORK_READY, WORKING, PACK_READY, PACKING, DONE }

var _phase := Phase.NOT_STARTED
var _remaining := 0.0
var _bad_day := false
var _piece_finished := false
var _finish_today := false
var _repair_needed := false

var done: bool:
	get: return _phase == Phase.DONE
var bad_day: bool:
	get: return _bad_day
var piece_finished: bool:
	get: return _piece_finished
var busy: bool:
	get: return _phase in [Phase.UNROLLING, Phase.WORKING, Phase.PACKING]
var unrolled: bool:
	get: return _phase in [Phase.WORK_READY, Phase.WORKING, Phase.PACK_READY, Phase.PACKING]
var working: bool:
	get: return _phase == Phase.WORKING
var prompt: String:
	get:
		match _phase:
			Phase.UNROLL_READY: return "E  Unroll the length"
			Phase.WORK_READY: return "E  Repair the section" if _repair_needed else "E  Work a section"
			Phase.PACK_READY: return "E  Finish the piece" if _finish_today else "E  Pack for tomorrow"
		return ""
var feeling := "The groceries are home. Mother has the thread ready."


func start(finish_piece_today := false, repair_needed := false) -> void:
	if _phase != Phase.NOT_STARTED:
		return
	_finish_today = finish_piece_today
	_repair_needed = repair_needed
	if _repair_needed:
		feeling = "The returned piece waits. Mother finds the loose section."
	_phase = Phase.UNROLL_READY
	changed.emit()


func interact() -> bool:
	match _phase:
		Phase.UNROLL_READY:
			_phase = Phase.UNROLLING
			_remaining = 0.7
			feeling = "Together they unroll the long rectangular piece."
		Phase.WORK_READY:
			_phase = Phase.WORKING
			_remaining = 1.5
			feeling = "She repairs the loose section. Mother sews beside her." if _repair_needed else "She stitches this section. Mother works beside her."
		Phase.PACK_READY:
			_phase = Phase.PACKING
			_remaining = 0.7
			feeling = "Together they tie off the last threads." if _finish_today else "They fold the length carefully for tomorrow."
		_:
			return false
	changed.emit()
	return true


func advance(delta: float) -> void:
	if not busy or delta <= 0.0:
		return
	_remaining -= delta
	if _remaining > 0.0:
		return
	match _phase:
		Phase.UNROLLING: _phase = Phase.WORK_READY
		Phase.WORKING: _phase = Phase.PACK_READY
		Phase.PACKING:
			_phase = Phase.DONE
			_piece_finished = _finish_today
			feeling = "The piece is ready to carry to Phú Hòa." if piece_finished else "A section is sewn. The rest will wait until tomorrow."
	changed.emit()


func skip() -> bool:
	if done or _phase == Phase.NOT_STARTED:
		return false
	_bad_day = true
	_phase = Phase.DONE
	feeling = "The sewing waits. The household will feel the missed work."
	changed.emit()
	return true
