extends CanvasLayer

@onready var place_label: Label = $Place
@onready var feeling_label: Label = $Feeling
@onready var prompt_label: Label = $Prompt
@onready var notice_label: Label = $Notice
@onready var lean_bar: ColorRect = $LeanBack/Lean
@onready var lean_back: ColorRect = $LeanBack
@onready var help_label: Label = $Help
@onready var evening_tint: ColorRect = $EveningTint

var _run: WaterRunState
var _groceries: GroceriesState
var _evening: EveningState


func setup(run: WaterRunState, groceries: GroceriesState, evening: EveningState) -> void:
	_run = run
	_groceries = groceries
	_evening = evening
	_run.changed.connect(_refresh)
	_groceries.changed.connect(_refresh)
	_evening.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _evening.started:
		_refresh_evening()
		return
	if _groceries.started:
		_refresh_groceries()
		return
	evening_tint.visible = false
	place_label.text = _run.place_name
	feeling_label.text = _run.feeling
	prompt_label.text = _run.prompt
	notice_label.text = _run.notice
	lean_back.visible = _run.loaded
	help_label.visible = not _run.loaded
	if _run.loaded:
		var mid := 48.0
		lean_bar.position.x = mid + _run.lean * 40.0 - lean_bar.size.x / 2.0
	if _run.done:
		help_label.text = ""
	elif _run.loaded:
		help_label.text = "Walk straight. Weave around glass. Shift hurries."
	else:
		help_label.text = "WASD. Walk east to the stream in Phú Bình."


func _refresh_evening() -> void:
	evening_tint.visible = true
	place_label.text = "Household · Evening"
	feeling_label.text = _evening.feeling
	prompt_label.text = _evening.prompt
	notice_label.text = _evening.notice if _evening.notice != "" else _run.notice
	lean_back.visible = false
	if _evening.asleep:
		help_label.text = ""
	elif _evening.prompt == "E  Broom    B  Bed":
		help_label.text = "E sweeps. B sleeps now; morning will feel it."
	else:
		help_label.text = "E continues the household beat."


func _refresh_groceries() -> void:
	evening_tint.visible = false
	place_label.text = _groceries.place_name()
	feeling_label.text = _groceries.feeling
	prompt_label.text = _groceries.prompt
	notice_label.text = _groceries.notice if _groceries.notice != "" else _run.notice
	lean_back.visible = false
	if _groceries.busy or _groceries.done:
		help_label.text = ""
	else:
		help_label.text = "WASD. No yoke; this is the short Groceries walk."
