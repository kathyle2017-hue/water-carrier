class_name DayMemoryStore
extends RefCounted

## The Bed persistence boundary. Only the last completed day and count are
## retained; unfinished play never changes the file.
const DEFAULT_PATH := "user://day_memory.json"

var _path: String


func _init(path := DEFAULT_PATH) -> void:
	_path = path


func remember_day(bad_day: bool, broom_skipped: bool, progress: Dictionary = {}) -> Error:
	var previous := load_last_day()
	var remembered := {
		"completed_days": int(previous.get("completed_days", 0)) + 1,
		"bad_day": bad_day,
		"broom_skipped": broom_skipped,
		"progress": progress,
	}
	var directory := ProjectSettings.globalize_path(_path.get_base_dir())
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK and error != ERR_ALREADY_EXISTS:
		return error
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(remembered))
	file.flush()
	return OK


func load_last_day() -> Dictionary:
	if not FileAccess.file_exists(_path):
		return {}
	var file := FileAccess.open(_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		return {}
	return {
		"completed_days": maxi(0, int(parsed.get("completed_days", 0))),
		"bad_day": bool(parsed.get("bad_day", false)),
		"broom_skipped": bool(parsed.get("broom_skipped", false)),
		"progress": parsed.get("progress", {}) if parsed.get("progress", {}) is Dictionary else {},
	}
