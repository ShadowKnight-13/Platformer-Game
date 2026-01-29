extends CharacterBody2D

const SPEED = 300.0
const JUMP_HEIGHT: float = -500.0
const FRICTION: float = 22.5

const GRAVITY_NORMAL: float = 14.5
const GRAVITY_WALL_SLIDE: float = 100.5
const WALL_JUMP_PUSH_FORCE: float = 600.0  # Increased for more noticeable push

var wall_stick_time := 0.0
const WALL_STICK_DURATION := 0.5

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.15  # Slightly longer for better control

var health = 3
var is_wall_jumping := false

signal health_changed

func player_death():
	if health == 0:
		queue_free()
		get_tree().reload_current_scene()

func kill_player():
	health = 0

func damage_player():
	health = health - 1
	emit_signal("health_changed", health)

func _physics_process(delta):
	var x_input = Input.get_axis("move_left", "move_right")
	
	# Determine which wall we're on (-1 for left wall, 1 for right wall, 0 for no wall)
	var wall_normal = get_wall_normal()
	var on_left_wall = wall_normal.x > 0  # Left wall has positive normal (points right)
	var on_right_wall = wall_normal.x < 0  # Right wall has negative normal (points left)
	
	# Check if player is pressing INTO the wall
	var pressing_into_wall = false
	if on_left_wall and x_input < 0:  # Pressing left into left wall
		pressing_into_wall = true
	elif on_right_wall and x_input > 0:  # Pressing right into right wall
		pressing_into_wall = true
	
	# Wall Stick & Wall Jump Logic
	var is_wall_sliding = false  # Track if we're wall sliding for animation
	
	if is_on_wall() and not is_on_floor() and pressing_into_wall:
		# Player is on wall and pressing into it
		is_wall_sliding = true  # Set flag for animation system
		
		if wall_stick_time < WALL_STICK_DURATION:
			# Stick to wall (no sliding)
			wall_stick_time += delta
			velocity.y = 0
		else:
			# After stick duration, slide down slowly
			velocity.y = GRAVITY_WALL_SLIDE
		
		# Handle wall jump
		if Input.is_action_just_pressed("jump"):
			# Jump up and away from wall
			velocity.y = JUMP_HEIGHT
			velocity.x = wall_normal.x * WALL_JUMP_PUSH_FORCE  # Push away from wall
			wall_jump_lock = WALL_JUMP_LOCK_TIME
			is_wall_jumping = true
			wall_stick_time = 0.0  # Reset stick time
	else:
		# Not on wall or not pressing into it
		wall_stick_time = 0.0
		
		# Apply normal gravity
		if not is_on_floor():
			velocity.y += GRAVITY_NORMAL
	
	# Ground jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_HEIGHT
	
	# Horizontal movement
	if wall_jump_lock > 0.0:
		# During wall jump lock, reduce player control
		wall_jump_lock -= delta
		velocity.x = lerp(velocity.x, x_input * SPEED, 0.075)  # Less control during wall jump
	else:
		is_wall_jumping = false
		# Normal movement control
		if x_input != 0:
			velocity.x = lerp(velocity.x, x_input * SPEED, 0.15)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION)
	
	# === ANIMATION HANDLING ===
	if is_wall_sliding:
	# Player is on wall - play wall slide animation
		$AnimationPlayer.play("Wall_slide")
		print("Slide")
	
	# Flip sprite based on which wall we're on
		if on_left_wall:
			$Sprite2D.flip_h = true  # Face right when on left wall
		elif on_right_wall:
			$Sprite2D.flip_h = false  # Face left when on right wall
		
	elif not is_on_floor():  # ← Changed to elif
	# In air but not wall sliding
		if velocity.y < 0:
			$AnimationPlayer.play("Jump")
		else:
			$AnimationPlayer.play("Fall")
	
		# Sprite flipping for air movement
		if x_input < 0:
			$Sprite2D.flip_h = true
		elif x_input > 0:
			$Sprite2D.flip_h = false
		
	else:
	# On ground
		if x_input != 0:
			$AnimationPlayer.play("Run")
		else:
			$AnimationPlayer.play("Idle")
	
	# Sprite flipping for ground movement
		if x_input < 0:
			$Sprite2D.flip_h = true
		elif x_input > 0:
			$Sprite2D.flip_h = false
	
	move_and_slide()
	player_death()
