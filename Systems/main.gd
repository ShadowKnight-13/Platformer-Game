extends Node2D

func _ready() -> void:
	var player: Node2D = $Player
	var spawn_pos: Vector2
	var spawn_health: int

	if CheckpointManager.has_checkpoint():
		spawn_pos = CheckpointManager.get_spawn_position()
		spawn_health = CheckpointManager.get_spawn_health()
	else:
		spawn_pos = Vector2(200, 200)
		spawn_health = 3

	player.global_position = spawn_pos
	player.health = spawn_health
	player.emit_signal("health_changed", player.health)

func _process(delta: float) -> void:
	pass

