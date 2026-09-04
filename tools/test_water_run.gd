extends SceneTree

## Water run rules, exercised through the same interface as play.
var failures := 0


func _init() -> void:
	_test_fill_and_unload()
	_test_glass_and_refill()
	_test_notifications()
	if failures == 0:
		print("water run rules ok")
	quit(1 if failures else 0)


func _test_fill_and_unload() -> void:
	var run := WaterRunState.new()
	_expect(not run.interact(), "cannot Fill away from the stream")
	run.enter_fill(true)
	_expect(run.interact(), "Fill starts at the stream")
	_expect(run.filling and not run.loaded, "jugs stay light during Fill")
	_expect(not run.interact(), "cannot restart a busy Fill")
	run.advance(1.0, Vector2.ZERO, false)
	_expect(run.filling, "Fill takes time")
	run.advance(0.8, Vector2.ZERO, false)
	_expect(run.loaded and not run.busy, "Fill finishes with loaded jugs")
	_expect(not run.interact(), "cannot Fill loaded jugs")
	run.enter_fill(false)
	run.enter_unload(true)
	_expect(run.interact(), "Unload starts at home")
	run.advance(1.4, Vector2.ZERO, false)
	_expect(run.done and not run.loaded and not run.busy, "Unload completes the Water run")
	_expect(run.movement_speed(false) == 0.0, "the Water run stops owning movement after Unload")
	_expect(run.feeling == "Clean water is home.", "completion reports clean water")
	var completed_notice := run.notice
	run.step_on_glass()
	_expect(run.notice == completed_notice, "Glass belongs to the Water run, not the walk to Đông")
	run.enter_unload(false)
	run.enter_fill(true)
	_expect(not run.interact(), "completed Water run cannot restart")


func _test_glass_and_refill() -> void:
	var run := WaterRunState.new()
	_expect(run.movement_speed(false) == 58.0, "light walk starts at normal speed")
	run.step_on_glass()
	_expect(run.bad_day and run.movement_speed(false) == 18.0, "Glass slows a light walk and makes a Bad day")
	run.advance(1.5, Vector2.ZERO, false)
	_expect(run.movement_speed(false) == 58.0, "hurt slowdown wears off")
	run.enter_fill(true)
	run.interact()
	_expect(run.movement_speed(true) == 0.0, "Fill stops movement, even when hurrying")
	run.advance(1.8, Vector2.ZERO, false)
	run.enter_fill(false)
	_expect(run.movement_speed(false) == 30.0 and run.movement_speed(true) == 46.0, "loaded walking is heavy; hurry is faster")
	# Glass is deterministic: three bad steps tip full jugs without random walking.
	run.step_on_glass()
	run.step_on_glass()
	run.step_on_glass()
	_expect(not run.loaded and not run.done and is_zero_approx(run.lean), "spill empties both jugs and resets balance")
	_expect(run.bad_day and run.notice == "The water is gone. She still has to Fill.", "spill preserves Bad day and explains refill")
	run.enter_unload(true)
	_expect(not run.interact(), "empty jugs cannot be Unloaded")
	run.enter_unload(false)
	run.enter_fill(true)
	_expect(run.interact(), "spilled water can be fetched again")
	run.advance(1.8, Vector2.ZERO, false)
	run.enter_fill(false)
	run.enter_unload(true)
	run.interact()
	run.advance(1.4, Vector2.ZERO, false)
	_expect(run.done and run.bad_day, "refill and Unload do not erase Bad day")
	_expect(run.notice == "The household has water. They will feel the day.", "household receives the Bad day outcome")
	var next_run := WaterRunState.new()
	_expect(not next_run.done and not next_run.bad_day and not next_run.loaded, "another Water run starts independently")


func _test_notifications() -> void:
	var run := WaterRunState.new()
	var observed := {"fill": false, "completion": false}
	var observe := func():
		if run.done:
			observed.completion = true
			_expect(not run.loaded and not run.busy, "completion notification has settled load and timing")
			_expect(run.feeling == "Clean water is home." and run.notice == "The household has water.", "completion notification includes the household outcome")
		if run.filling:
			observed.fill = true
			_expect(run.prompt == "Fill" and not run.loaded, "Fill notification includes its prompt and load")
	run.changed.connect(observe)
	run.enter_fill(true)
	run.interact()
	run.advance(1.8, Vector2.ZERO, false)
	run.enter_fill(false)
	run.enter_unload(true)
	run.interact()
	run.advance(1.4, Vector2.ZERO, false)
	run.changed.disconnect(observe)
	_expect(observed.fill, "Fill notifies observers")
	_expect(observed.completion, "completion notifies observers")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
