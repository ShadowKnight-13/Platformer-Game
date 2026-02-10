extends StaticBody2D

# Reference to the health system (autoload)
@onready var health_system = get_node("/root/Health")

# Reference to the interactable Area2D
@onready var interactable: Area2D = $interactable

# How much health this med kit restores
@export var heal_amount: int = 1

# Store if this med kit has been used
var has_been_used: bool = false

func _ready() -> void:
	# Connect the interact function to be called when player uses this med kit
	interactable.interact = _on_interact
	
	# Make sure the interactable is active at the start
	interactable.is_interactable = true


func _on_interact():
	# Only heal if the med kit hasn't been used yet in this checkpoint
	if not has_been_used:
		# Call the heal function from the health system
		health_system.heal(heal_amount)
		
		# Mark this med kit as used
		has_been_used = true
		
		# Optional: Make the med kit disappear visually
		$Sprite2D.visible = false
		
		# Optional: Print a message so we know it worked
		print("Med kit used! Player healed for ", heal_amount, " health")
