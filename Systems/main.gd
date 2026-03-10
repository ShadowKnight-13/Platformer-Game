extends Node2D

@export var level_scene: PackedScene
@export var default_spawn_position: Vector2 = Vector2(200, 200)
@export var default_spawn_health: int = 3

func _ready() -> void:
	var level_instance: Node = null
	if level_scene:
		var level_placeholder: Node = $Level
		level_instance = level_scene.instantiate()
		level_instance.name = "Level"
		add_child(level_instance)
		level_placeholder.queue_free()

	var player: Node2D = $Player
	var spawn_pos: Vector2
	var spawn_health: int

	if CheckpointManager.has_checkpoint():
		spawn_pos = CheckpointManager.get_spawn_position()
		spawn_health = CheckpointManager.get_spawn_health()
	else:
		# Prefer a per-level SpawnPoint marker if it exists
		if level_instance:
			var spawn_point := level_instance.get_node_or_null("SpawnPoint")
			if spawn_point and spawn_point is Node2D:
				spawn_pos = spawn_point.global_position
			else:
				spawn_pos = default_spawn_position
		else:
			spawn_pos = default_spawn_position

		spawn_health = default_spawn_health

	player.global_position = spawn_pos
	player.health = spawn_health
	player.emit_signal("health_changed", player.health)

func _process(delta: float) -> void:
	pass

