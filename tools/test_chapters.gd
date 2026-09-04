extends SceneTree
var failures := 0
func _init() -> void:
	var story := ChapterProgress.new()
	_expect(story.day_kind == "school" and story.father_home, "School opens before the camps with Father home")
	story.finish_day(false)
	story.finish_day(false)
	_expect(story.needs_1975_scene and not story.father_home, "1975 sits inside the School season")
	story.see_1975()
	_expect(not story.needs_1975_scene, "the scene continues into class once")
	story.finish_day(false)
	_expect(story.day_kind == "school_parcel", "School parcel skips class after the capture")
	for i in 3:
		story.finish_day(false)
	_expect(story.can_change_chapter, "School has an open stretch before chapter change")
	story.finish_day(true)
	_expect(story.chapter == "quiet" and story.flood_opening, "quiet year opens with flood days")
	story.finish_day(false)
	_expect(story.flood_opening, "1978 is lived as multiple days")
	story.finish_day(false)
	_expect(not story.flood_opening and not story.finish_piece_today, "ordinary later rain is separate from 1978 deaths")
	story.finish_day(false)
	_expect(story.finish_piece_today, "a finished piece can go to Evaluate")
	story.needs_repair = true
	var restored := ChapterProgress.new(story.snapshot())
	_expect(restored.needs_repair and restored.finish_piece_today, "repair survives Bed and is worked on a later sewing day")
	story.finish_day(false)
	story.finish_day(false)
	_expect(story.day_kind == "parcel" and not story.finish_piece_today, "Parcel cannot stack with Evaluate")
	_expect(not story.can_change_chapter, "pending repair prevents abandoning the sewing era")
	var blocked := ChapterProgress.new(story.snapshot())
	blocked.finish_day(true)
	_expect(blocked.chapter == "quiet" and blocked.needs_repair, "even an attempted chapter change preserves the rejected piece")
	story.needs_repair = false # The Office accepted the repaired piece.
	story.finish_day(true)
	_expect(story.chapter == "quan" and story.day_kind == "quan", "Quán begins only after the sewing era")
	for i in 6:
		story.finish_day(false)
	story.finish_day(true)
	_expect(story.chapter == "return", "1984–88 jumps straight to Return")
	story.finish_day(true)
	_expect(story.chapter == "return", "Return never opens another school day")
	print("chapter rules ok" if failures == 0 else "chapter rules failed")
	quit(1 if failures else 0)
func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
