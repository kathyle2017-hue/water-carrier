extends SceneTree

## Groceries rules, exercised through the same movement and action interface as play.
var failures := 0


func _init() -> void:
	_test_walk_to_dong_starts_only_after_the_water_run()
	_test_stall_is_one_short_list_pay_or_barter_bag_beat()
	_test_returning_home_completes_groceries()
	if failures == 0:
		print("groceries rules ok")
	quit(1 if failures else 0)


func _test_walk_to_dong_starts_only_after_the_water_run() -> void:
	var groceries := GroceriesState.new()
	_expect(groceries.movement_speed() == 0.0, "Groceries wait for Unload")
	groceries.start()
	_expect(groceries.movement_speed() == 58.0, "the walk to Đông uses ordinary walking speed")
	_expect(groceries.prompt == "Walk to Đông", "the next destination is Đông")
	_expect(not groceries.interact(), "the stall cannot be used away from Đông")
	groceries.enter_dong(true)
	_expect(groceries.prompt == "E  Groceries", "Đông offers the short stall beat")


func _test_stall_is_one_short_list_pay_or_barter_bag_beat() -> void:
	var groceries := _at_dong()
	_expect(groceries.interact(), "the stall starts through the play action")
	_expect(groceries.shopping and groceries.feeling == "List: greens, rice, salt.", "the stall begins with the list")
	_expect(groceries.movement_speed() == 0.0, "the short stall beat holds the water-carrier still")
	groceries.advance(0.6)
	_expect(groceries.shopping and groceries.feeling == "Pay or barter.", "the stall continues with pay or barter")
	groceries.advance(0.6)
	_expect(groceries.shopping and groceries.feeling == "Bag.", "the stall continues with the bag")
	groceries.advance(0.6)
	_expect(not groceries.busy and groceries.prompt == "Walk home", "the stall ends with the ordinary walk home")


func _test_returning_home_completes_groceries() -> void:
	var groceries := GroceriesState.new()
	groceries.start()
	groceries.enter_household(true)
	_expect(not groceries.done, "the trip cannot finish before visiting Đông")
	groceries.enter_household(false)
	groceries.enter_dong(true)
	groceries.interact()
	groceries.advance(1.6)
	groceries.enter_dong(false)
	groceries.enter_household(true)
	_expect(groceries.done and groceries.movement_speed() == 0.0, "walking home completes Groceries")
	_expect(groceries.notice == "Groceries are home.", "the completed trip reports the bag home")


func _at_dong() -> GroceriesState:
	var groceries := GroceriesState.new()
	groceries.start()
	groceries.enter_dong(true)
	return groceries


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
