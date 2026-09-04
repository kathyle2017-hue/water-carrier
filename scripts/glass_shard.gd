extends Area2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("step_on_glass"):
		body.step_on_glass()
