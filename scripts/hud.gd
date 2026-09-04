extends CanvasLayer

@onready var place_label: Label = $Place
@onready var feeling_label: Label = $Feeling
@onready var prompt_label: Label = $Prompt
@onready var notice_label: Label = $Notice
@onready var lean_bar: ColorRect = $LeanBack/Lean
@onready var lean_back: ColorRect = $LeanBack
@onready var help_label: Label = $Help

var _run: WaterRunState


func setup(run: WaterRunState) -> void:
	_run = run
	_run.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
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
