extends CanvasLayer

@onready var place_label: Label = $Place
@onready var feeling_label: Label = $Feeling
@onready var prompt_label: Label = $Prompt
@onready var notice_label: Label = $Notice
@onready var lean_bar: ColorRect = $LeanBack/Lean
@onready var lean_back: ColorRect = $LeanBack
@onready var help_label: Label = $Help


func _ready() -> void:
	RunState.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	place_label.text = RunState.place_name
	feeling_label.text = RunState.feeling
	prompt_label.text = RunState.prompt
	notice_label.text = RunState.notice
	lean_back.visible = RunState.loaded
	help_label.visible = not RunState.loaded
	if RunState.loaded:
		var mid := 48.0
		lean_bar.position.x = mid + RunState.lean * 40.0 - lean_bar.size.x / 2.0
	if RunState.done:
		help_label.text = ""
	elif RunState.loaded:
		help_label.text = "Walk straight. Weave around glass. Shift hurries."
	else:
		help_label.text = "WASD. Walk east to the stream in Phú Bình."
