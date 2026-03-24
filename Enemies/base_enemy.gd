extends CharacterBody2D
class_name BaseEnemy

@export var max_health: int = 2
@export var death_effect_scene: PackedScene
var health: int = 0

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health -= amount
	play_hit_flash()
	if health <= 0:
		die()

func die() -> void:
	if death_effect_scene:
		print('scene exists')
		var effect = death_effect_scene.instantiate()
		
		# Add the effect to the level (the enemy's parent) 
		# so it stays in the world even after the enemy is gone
		get_parent().add_child(effect)
		
		# Move the effect to the enemy's current position
		effect.global_position = global_position
	queue_free()
	
func play_hit_flash() -> void:
	# Create a tween (a one-time interpolation object)
	var tween = create_tween()
	
	# 1. Flash to white/red immediately
	# "modulate" tints the sprite. Setting it to a high value like 10.0 
	# makes it look like it's glowing if you have HDR/Glow enabled, 
	# or just a solid bright color otherwise.
	modulate = Color(10, 10, 10, 1) # Bright White
	# Or use Color.RED if you prefer a red flash
	
	# 2. Transition back to normal color over 0.1 seconds
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
