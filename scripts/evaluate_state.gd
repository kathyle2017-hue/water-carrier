extends RefCounted

## The one authored Office visit. Admission and later repair belong to the Day.
signal changed

enum Phase { NOT_STARTED, OUTWARD, HALL, QA, RESULT, LEAVE_HALL, HOMEWARD, DONE }

var phase := Phase.NOT_STARTED
var carrier_position := Vector2(40, 112)
var needs_repair := false
var bad_day := false
var feeling := ""
var _piece_repaired := false

var done: bool:
	get: return phase == Phase.DONE
var outside: bool:
	get: return phase in [Phase.OUTWARD, Phase.HOMEWARD, Phase.DONE]
var hall: bool:
	get: return phase in [Phase.HALL, Phase.LEAVE_HALL]
var place: String:
	get:
		if hall:
			return "Phú Hòa · Office hall"
		if phase in [Phase.QA, Phase.RESULT]:
			return "Phú Hòa · Military QA"
		return "Huế · Walk to Phú Hòa" if phase == Phase.OUTWARD else "Huế · Walk home"
var prompt: String:
	get:
		match phase:
			Phase.OUTWARD:
				return "E  Enter the Office" if _near(Vector2(592, 104)) else "Walk the piece to Phú Hòa →"
			Phase.HALL:
				return "E  Enter QA" if _near(Vector2(272, 92)) else "Walk past the doors to QA →"
			Phase.QA:
				return "E  Evaluate" if _near(Vector2(216, 108)) else "Bring the piece to the desk →"
			Phase.RESULT:
				return "E  Take the piece home to fix" if needs_repair else "E  Thank them and leave"
			Phase.LEAVE_HALL:
				return "E  Leave the Office" if _near(Vector2(40, 128)) else "Walk back through the hall ←"
			Phase.HOMEWARD:
				return "E  Home for Evening" if _near(Vector2(40, 112)) else "Walk home ←"
		return ""


func start(piece_repaired: bool) -> void:
	if phase != Phase.NOT_STARTED:
		return
	_piece_repaired = piece_repaired
	phase = Phase.OUTWARD
	feeling = "The piece is finished. Mother stays home."
	changed.emit()


func move(direction: Vector2, delta: float) -> void:
	if phase in [Phase.NOT_STARTED, Phase.RESULT, Phase.DONE]:
		return
	carrier_position += direction.limit_length(1.0) * 58.0 * maxf(delta, 0.0)
	carrier_position.x = clampf(carrier_position.x, 24.0, 608.0 if outside else 292.0)
	carrier_position.y = clampf(carrier_position.y, 92.0, 132.0)
	changed.emit()


func interact() -> bool:
	match phase:
		Phase.OUTWARD:
			if not _near(Vector2(592, 104)):
				return false
			phase = Phase.HALL
			carrier_position = Vector2(40, 128)
			feeling = "Many offices, many people. QA is the last door."
		Phase.HALL:
			if not _near(Vector2(272, 92)):
				return false
			phase = Phase.QA
			carrier_position = Vector2(56, 120)
			feeling = "Military QA checks each length before it goes on."
		Phase.QA:
			if not _near(Vector2(216, 108)):
				return false
			phase = Phase.RESULT
			needs_repair = not _piece_repaired
			bad_day = needs_repair
			feeling = "This edge needs fixing. Bring it back after sewing." if needs_repair else "Accepted. This length can go to China and Russia."
		Phase.RESULT:
			phase = Phase.LEAVE_HALL
			carrier_position = Vector2(272, 92)
			feeling = "The offices carry on. It is time to walk home."
		Phase.LEAVE_HALL:
			if not _near(Vector2(40, 128)):
				return false
			phase = Phase.HOMEWARD
			carrier_position = Vector2(592, 104)
			feeling = "Mother is at home. Evening still waits."
		Phase.HOMEWARD:
			if not _near(Vector2(40, 112)):
				return false
			phase = Phase.DONE
			feeling = "Home for Talk, Pot, and Broom."
		_:
			return false
	changed.emit()
	return true


func _near(target: Vector2) -> bool:
	return carrier_position.distance_to(target) <= 20.0
