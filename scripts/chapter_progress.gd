class_name ChapterProgress
extends RefCounted

## The biography calendar. Seasons remain open for ordinary days; at Bed the
## player can move on after the same minimum stretch in each season.
const SEASONS := ["school", "quiet", "quan", "return"]
const SEASON_DAYS := 6
var chapter := "school"
var day := 0
var needs_repair := false
var _saw_1975 := false

var father_home: bool:
	get: return chapter == "return" or (chapter == "school" and day < 2)
var needs_1975_scene: bool:
	get: return chapter == "school" and day >= 2 and not _saw_1975
var flood_opening: bool:
	get: return chapter == "quiet" and day < 2
var day_kind: String:
	get:
		if chapter == "school":
			return "school_parcel" if day >= 3 and day % 3 == 0 else "school"
		if chapter == "quiet":
			return "parcel" if day > 2 and day % 5 == 0 else "quiet"
		if chapter == "quan":
			return "parcel" if day % 3 == 2 else "quan"
		return "return"
var finish_piece_today: bool:
	get: return day_kind == "quiet" and not flood_opening and (needs_repair or (day >= 3 and day % 3 == 0))
var can_change_chapter: bool:
	get: return chapter != "return" and day + 1 >= SEASON_DAYS and not needs_repair

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
