extends Node
# Autoload script that holds the last checkpoint reached
# a spawn point.

var last_position: Vector2 = Vector2.INF
var last_health: int = 3

signal checkpoint_reached(position: Vector2, health:int)

func set_checkpoint(position: Vector2, health: int) -> void:
	last_position = position
	last_health = clampi(health, 0, 3)

func get_spawn_position() -> Vector2:
	return last_position

func get_spawn_health() -> int:
	return last_health

func has_checkpoint() -> bool:
	return last_position != Vector2.INF
