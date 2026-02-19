extends StaticBody2D

var health_system  # This will reference the autoload singleton

# Reference to the interactable Area2D
@onready var interactable: Area2D = $interactable

# How much health this med kit restores
@export var heal_amount: int = 1

# Store if this med kit has been used
var has_been_used: bool = false

func _ready() -> void:
	# Get reference to the health system autoload
	health_system = get_node("/root/healthManager")  # Use exact name from project.godot
	
	# Connect the interact function...
	interactable.interact = _on_interact

	CheckpointManager.connect("checkpoint_reached", Callable(self, "_on_checkpoint_reached"))

func _on_interact():
	# Only heal if the med kit hasn't been used yet in this checkpoint
	if not has_been_used:
		# Get the Player node and call heal on it
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("heal"):
			health_system.heal(heal_amount)
		
		# Mark this med kit as used
		has_been_used = true
		
		# Optional: Make the med kit disappear visually
		$Sprite2D.visible = false
		
		# Optional: Print a message so we know it worked
		print("Med kit used! Player healed for ", heal_amount, " health")

func _on_checkpoint_reached(_position: Vector2, _health: int):
	# When a checkpoint is reached, reset this med kit
	has_been_used = false
	$Sprite2D.visible = true
	interactable.is_interactable = true
	print("Med kit reset at checkpoint")
