extends CharacterBody2D
class_name BaseEnemy

@export var max_health: int = 2
var health: int = 0

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()
