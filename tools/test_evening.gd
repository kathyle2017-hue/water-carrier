extends SceneTree

## Evening rules, exercised through the same action interface as play.
var failures := 0


func _init() -> void:
	_test_talk_opens_the_evening()
	_test_talk_reflects_the_day_without_a_dialogue_tree()
	_test_pot_is_one_short_chop_stir_serve_beat()
	_test_broom_completes_the_night_must_before_bed()
	_test_bed_can_skip_broom_but_the_household_feels_it()
	_test_bed_outcome_is_remembered_for_the_next_morning()
	_test_skipped_broom_is_felt_the_next_morning()
	if failures == 0:
		print("evening rules ok")
	quit(1 if failures else 0)


func _test_talk_opens_the_evening() -> void:
	var evening := EveningState.new()
	evening.start(false)
	_expect(evening.prompt == "E  Talk", "Evening opens with Talk at the bowl")
	_expect(evening.interact(), "Talk starts through the play action")
	_expect(evening.talking and evening.busy, "Talk is a short authored beat")


func _test_talk_reflects_the_day_without_a_dialogue_tree() -> void:
	var good_evening := EveningState.new()
	good_evening.start(false)
	good_evening.interact()
	_expect(good_evening.feeling == "Mother: The rain let you home. Sister: Eat while it is warm.", "a good day has a warm authored Talk")
	good_evening.advance(1.3)
	_expect(not good_evening.busy and good_evening.prompt == "E  Pot", "Talk ends at the next household beat")

	var bad_evening := EveningState.new()
	bad_evening.start(true)
	bad_evening.interact()
	_expect(bad_evening.feeling == "Mother sees the day in her shoulders. Sister makes room at the bowl.", "a Bad day changes the Talk tone")
	_expect(bad_evening.bad_day, "Evening preserves the Bad day")


func _test_pot_is_one_short_chop_stir_serve_beat() -> void:
	var evening := _after_talk()
	_expect(evening.interact(), "Pot starts through the play action")
	_expect(evening.cooking and evening.feeling == "Chop.", "Pot begins with chop")
	evening.advance(0.6)
	_expect(evening.cooking and evening.feeling == "Stir.", "Pot continues with stir")
	evening.advance(0.6)
	_expect(evening.cooking and evening.feeling == "Serve the bowl.", "Pot continues with serve")
	evening.advance(0.6)
	_expect(not evening.busy and evening.prompt == "E  Broom    B  Bed", "the short Pot beat opens the night choice")


func _test_broom_completes_the_night_must_before_bed() -> void:
	var evening := _after_pot()
	_expect(evening.interact(), "Broom starts through the play action")
	_expect(evening.sweeping and evening.busy, "Broom is a short night beat")
	evening.advance(1.4)
	_expect(evening.broom_done and evening.prompt == "B  Bed", "completed Broom leads to Bed")
	_expect(evening.sleep(), "Bed closes a swept evening")
	_expect(evening.asleep and not evening.broom_skipped and not evening.bad_day, "a swept good day sleeps without a hangover")


func _test_bed_can_skip_broom_but_the_household_feels_it() -> void:
	var evening := _after_pot()
	_expect(evening.sleep(), "Bed remains available when Broom is skipped")
	_expect(evening.asleep and evening.broom_skipped, "Bed records the skipped Broom")
	_expect(evening.bad_day, "skipping the night must makes a Bad day")
	_expect(evening.notice == "The game remembers. The household will feel the unswept yard in the morning.", "Bed reports the next-morning consequence")


func _test_bed_outcome_is_remembered_for_the_next_morning() -> void:
	var save_path := OS.get_temp_dir().path_join("water-carrier-evening-%s.json" % Time.get_ticks_usec())
	var memory := DayMemoryStore.new(save_path)
	_expect(memory.remember_day(true, true) == OK, "Bed can remember the day")
	var remembered := DayMemoryStore.new(save_path).load_last_day()
	_expect(remembered.get("completed_days") == 1, "the remembered day count survives a reload")
	_expect(remembered.get("bad_day") == true and remembered.get("broom_skipped") == true, "the Bad day and skipped Broom survive a reload")
	DirAccess.remove_absolute(save_path)


func _test_skipped_broom_is_felt_the_next_morning() -> void:
	var next_morning := WaterRunState.new(true)
	_expect(next_morning.bad_day, "an unswept yard carries a Bad day hangover")
	_expect(next_morning.notice == "Leaves from last night still cling to the yard. Mother looks once.", "the household feels the skipped Broom in the morning")


func _after_talk(day_was_bad := false) -> EveningState:
	var evening := EveningState.new()
	evening.start(day_was_bad)
	evening.interact()
	evening.advance(1.3)
	return evening


func _after_pot(day_was_bad := false) -> EveningState:
	var evening := _after_talk(day_was_bad)
	evening.interact()
	evening.advance(1.6)
	return evening


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
