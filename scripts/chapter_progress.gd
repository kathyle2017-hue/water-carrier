class_name ChapterProgress
extends RefCounted

## The biography calendar. Seasons remain open for ordinary days; at Bed the
## player can move on after the same minimum stretch in each season.
const SEASONS := ["school", "quiet"]
const SEASON_DAYS := 6
var chapter := "school"
var day := 0
var needs_repair := false
var _saw_1975 := false

var father_home: bool:
	get: return chapter in ["school", "return"]
var needs_1975_scene: bool:
	get: return false
var flood_opening: bool:
	get: return false
var day_kind: String:
	get:
		if chapter == "school":
			return "school"
		if chapter == "quiet":
			return "quiet"
		if chapter == "quan":
			return "quan"
		return "return"
var finish_piece_today: bool:
	get: return false
var can_change_chapter: bool:
	get: return chapter != "quiet" and day + 1 >= SEASON_DAYS

func _init(saved: Dictionary = {}) -> void:
	var saved_chapter := str(saved.get("chapter", "school"))
	chapter = saved_chapter if saved_chapter in SEASONS else "school"
	day = maxi(0, int(saved.get("day", 0)))
	needs_repair = bool(saved.get("needs_repair", false))
	_saw_1975 = bool(saved.get("saw_1975", false))

func see_1975() -> void:
	_saw_1975 = true

func finish_day(change_chapter: bool) -> void:
	if chapter == "return":
		return
	if change_chapter and can_change_chapter:
		chapter = SEASONS[SEASONS.find(chapter) + 1]
		day = 0
		needs_repair = false
	else:
		day += 1

func snapshot() -> Dictionary:
	return {"chapter": chapter, "day": day, "needs_repair": needs_repair, "saw_1975": _saw_1975}
