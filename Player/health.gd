extends Node

signal health_changed

var player_health = 0
@export var max_player_health = 3

func _ready():
	player_health = max_player_health
	
func take_damage(amount):
	player_health -= amount
	player_health = max(0, player_health)
	emit_signal("health_changed", player_health)

func heal(amount):
	player_health += amount
	player_health = min(player_health, max_player_health)
	emit_signal("health_changed", player_health)
	
