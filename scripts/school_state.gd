class_name SchoolState
extends RefCounted

## A lesson stays in the classroom; the day ends only on returning home.
signal changed

enum Phase { WALK_TO_CLASS, COPY, REMEMBER, RECITE, WALK_HOME, DONE }
var _phase := Phase.WALK_TO_CLASS
var _at_class := false
var bad_day := false
var done: bool:
	get: return _phase == Phase.DONE
var walking_home: bool:
	get: return _phase == Phase.WALK_HOME
var feeling := "Rain on Huỳnh Thúc Kháng. She carries her books to class."
var prompt: String:
	get:
		if _phase == Phase.WALK_HOME:
			return "Walk home"
		if _phase == Phase.DONE:
			return ""
		if not _at_class:
			return "Walk to class"
		if _phase == Phase.REMEMBER:
			return "E  Remember"
		if _phase == Phase.RECITE:
			return "E  Recite"
		return "E  Copy"

func set_at_class(value: bool) -> void:
	_at_class = value
	if value and _phase == Phase.WALK_TO_CLASS:
		_phase = Phase.COPY
	changed.emit()

func set_at_home(value: bool) -> void:
	if value and _phase == Phase.WALK_HOME:
		_phase = Phase.DONE
		feeling = "Books set down. The household gathers for evening."
		changed.emit()

func interact() -> bool:
	if not _at_class:
		return false
	match _phase:
		Phase.COPY:
			feeling = "She copies a line. Rain taps the classroom roof."
			_phase = Phase.REMEMBER
		Phase.REMEMBER:
			feeling = "She closes the book and holds the words in mind."
			_phase = Phase.RECITE
		Phase.RECITE:
			feeling = "She recites. The lesson stays here; it is time to walk home."
			_phase = Phase.WALK_HOME
		_:
			return false
	changed.emit()
	return true
