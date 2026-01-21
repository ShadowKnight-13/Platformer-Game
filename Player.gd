extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -500.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 3

signal health_changed(health)

	
func player_death():
	if health == 0:
		queue_free()
		get_tree().reload_current_scene()
		
func kill_player():
	if Input.is_action_just_pressed("kill_player"):
		health = 0
		
func damage_player():
	if Input.is_action_just_pressed("damage_player"):
		health = health - 1
		emit_signal("health_changed", health)
		
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$AnimationPlayer.play("Jump")
	#Sprite flip check
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		$AnimationPlayer.play("Run")
		velocity.x = direction * SPEED
	else:
		$AnimationPlayer.play("Idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	damage_player()
	player_death()
	kill_player()
