extends Area2D

var _taken := false


func _ready() -> void:
	monitoring = true
	# Player CharacterBody2D uses collision_layer = 3 (world + player bits).
	collision_mask = 3
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _taken:
		return
	if body == null or not body.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	queue_free()
