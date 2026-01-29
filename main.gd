extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = $Player
	var spawn_pos: Vector2
	var spawn_health: int
	if CheckpointManager.has_checkpoint():
		spawn_pos = CheckpointManager.get_spawn_position()
		spawn_health = CheckpointManager.get_spawn_health()
	else:
		spawn_pos = Vector2(200, 200)
		spawn_health = 3
	pass # Replace with function body.
	player.global_position = spawn_pos
	player.health = spawn_health
	player.emit_signal("health_changed", player.health)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
