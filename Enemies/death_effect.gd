extends Node2D


func _ready() -> void:
	# Start the animation as soon as the effect is spawned
	$DeathEffect.play("Death")
	
	# Connect the signal that tells us when the animation is done
	$DeathEffect.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	# Delete the effect node entirely once the animation ends
	queue_free()
