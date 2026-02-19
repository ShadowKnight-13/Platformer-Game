extends StaticBody2D

@onready var interactable: Area2D = $interactable

@export var heal_amount: int = 1

var has_been_used: bool = false

func _ready() -> void:
	interactable.interacted.connect(_on_interact)
	CheckpointManager.checkpoint_reached.connect(_on_checkpoint_reached)

func _on_interact():
	if has_been_used:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("heal"):
		player.heal(heal_amount)
	has_been_used = true
	$Sprite2D.visible = false
	print("Med kit used! Player healed for ", heal_amount, " health")

func _on_checkpoint_reached(_position: Vector2, _health: int):
	has_been_used = false
	$Sprite2D.visible = true
	print("Med kit reset at checkpoint")
