class_name QuanState
extends RefCounted

## Afternoon only: the caller owns morning water and Evening.
signal changed

enum Phase { NOT_STARTED, STREET, BRIDGE, FAR_BANK, SHIFT, DONE }

const COUNTER := Vector2(40, 68)
const EXIT := Vector2(300, 146)
const TABLES: Array[Vector2] = [Vector2(104, 80), Vector2(176, 80), Vector2(112, 128), Vector2(266, 112)]

var table_positions: Array[Vector2]:
	get: return TABLES.duplicate()
var _tables: Array[String] = ["order?", "order?", "order?", "order?"]
var carrying := -1
var served := 0
var time_left := 75.0
var grip := 1.0
var _fall_time := 0.0
var notice := "Ride right toward Tràng Tiền."
var prompt: String:
	get:
		if cycling:
			return "WASD / arrows: bike   Shift: hurry" if not rainy else "Wet road. Ride gently; hurrying loses grip."
		if done:
			return "Home for Evening"
		if carrying >= 0:
			return "Carry tray to table %s · E serve" % (carrying + 1)
		if position.distance_to(COUNTER) <= 16:
			return "E  Pick up an ordered drink"
		if position.distance_to(EXIT) <= 16:
			return "E  Leave shift for home"
		return "E at table: take order · Counter: collect"
var _phase := Phase.NOT_STARTED
var position := Vector2(24, 113)
var rainy := false
var bad_day := false
var on_bridge: bool:
	get: return _phase == Phase.BRIDGE
var at_thong_hoi: bool:
	get: return _phase == Phase.FAR_BANK
var working: bool:
	get: return _phase == Phase.SHIFT
var done: bool:
	get: return _phase == Phase.DONE
var cycling: bool:
	get: return _phase in [Phase.STREET, Phase.BRIDGE, Phase.FAR_BANK]

func start(wet := true) -> void:
	if _phase != Phase.NOT_STARTED:
		return
	rainy = wet
	_phase = Phase.STREET
	changed.emit()

func move(direction: Vector2, delta: float, hurry := false) -> void:
	if working:
		position += direction.limit_length() * 58.0 * delta
		position = position.clamp(Vector2(16, 58), Vector2(304, 148))
		changed.emit()
		return
	if not cycling:
		return
	if _fall_time > 0.0:
		return
	if rainy and hurry and direction.length() > 0.1:
		grip = maxf(0.0, grip - delta * 0.7)
		if grip <= 0.0:
			bad_day = true
			_fall_time = 1.0
			notice = "A slip. Get up, breathe, and keep going."
			changed.emit()
			return
	else:
		grip = minf(1.0, grip + delta * 0.5)
	var speed := 68.0 if rainy else 80.0
	if hurry:
		speed *= 1.35
	position += direction.limit_length() * speed * delta
	position.y = clampf(position.y, 94, 131)
	position.x = maxf(16, position.x)
	if position.x >= 300:
		_phase += 1
		position = Vector2(24, 113)
		if working:
			notice = "Four tables. Take orders, collect at the counter, serve."
	changed.emit()

func advance(delta: float) -> void:
	if _fall_time > 0.0:
		_fall_time = maxf(0.0, _fall_time - delta)
		if _fall_time == 0.0:
			grip = 1.0
	if working:
		time_left = maxf(0.0, time_left - delta)
		if time_left == 0.0:
			_finish_shift()
	changed.emit()

func _finish_shift() -> void:
	bad_day = bad_day or served < 3
	_phase = Phase.DONE
	notice = "A thin shift. Home for the evening bowl." if bad_day else "The cups are cleared. Home for Evening."

func place_name() -> String:
	match _phase:
		Phase.STREET: return "Trần Hưng Đạo"
		Phase.BRIDGE: return "Tràng Tiền · Hương"
		Phase.FAR_BANK: return "Thong Hoi"
		Phase.SHIFT: return "Quán · near Thong Hoi"
	return "Home for Evening"

func table_status(table: int) -> String:
	return _tables[table] if table >= 0 and table < _tables.size() else ""

func interact() -> bool:
	if not working:
		return false
	if position.distance_to(EXIT) <= 16:
		_finish_shift()
		changed.emit()
		return true
	if position.distance_to(COUNTER) <= 16 and carrying == -1:
		carrying = _tables.find("ordered")
		if carrying >= 0:
			_tables[carrying] = "on tray"
			changed.emit()
			return true
	for table in range(TABLES.size()):
		if position.distance_to(TABLES[table]) > 16:
			continue
		if _tables[table] == "order?":
			_tables[table] = "ordered"
		elif carrying == table:
			_tables[table] = "served"
			carrying = -1
			served += 1
			if served == TABLES.size():
				_finish_shift()
		else:
			return false
		changed.emit()
		return true
	return false
