extends CharacterBody2D

const SPEED = 300.0
const JUMP_HEIGHT: float = -500.0
const JUMP_CUT_MULTIPLIER: float = 0.2  # How much to cut jump when released early
const FRICTION: float = 22.5

const GRAVITY_NORMAL: float = 16
const GRAVITY_WALL_SLIDE: float = 100.5
const WALL_JUMP_PUSH_FORCE: float = 600.0

var wall_stick_time := 0.0
const WALL_STICK_DURATION := 0.5

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.15

var health = 3
var is_wall_jumping := false
var is_jumping := false  # Track if player initiated a jump

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
	
	# Determine which wall we're on
	var wall_normal = get_wall_normal()
	var on_left_wall = wall_normal.x > 0
	var on_right_wall = wall_normal.x < 0
	
	# Check if player is pressing INTO the wall
	var pressing_into_wall = false
	if on_left_wall and x_input < 0:
		pressing_into_wall = true
	elif on_right_wall and x_input > 0:
		pressing_into_wall = true
	
	# Wall Stick & Wall Jump Logic
	var is_wall_sliding = false
	
	if is_on_wall() and not is_on_floor() and pressing_into_wall:
		is_wall_sliding = true
		
		if wall_stick_time < WALL_STICK_DURATION:
			wall_stick_time += delta
			velocity.y = 0
		else:
			velocity.y = GRAVITY_WALL_SLIDE
		
		# Handle wall jump
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_HEIGHT
			velocity.x = wall_normal.x * WALL_JUMP_PUSH_FORCE
			wall_jump_lock = WALL_JUMP_LOCK_TIME
			is_wall_jumping = true
			is_jumping = true  # Mark that we're jumping
			wall_stick_time = 0.0
	else:
		wall_stick_time = 0.0
		
		# Apply normal gravity
		if not is_on_floor():
			velocity.y += GRAVITY_NORMAL
	
	# Ground jump
	if is_on_floor():
		is_jumping = false  # Reset jump state when landing
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_HEIGHT
			is_jumping = true  # Mark that we're jumping
	
	# === VARIABLE JUMP HEIGHT - This is the new logic ===
	# If player releases jump button while moving upward, cut the jump short
	if Input.is_action_just_released("jump") and is_jumping and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER
	
	# Horizontal movement
	if wall_jump_lock > 0.0:
		wall_jump_lock -= delta
		velocity.x = lerp(velocity.x, x_input * SPEED, 0.075)
	else:
		is_wall_jumping = false
		if x_input != 0:
			velocity.x = lerp(velocity.x, x_input * SPEED, 0.15)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION)
	
	# === ANIMATION HANDLING ===
	if is_wall_sliding:
		$AnimationPlayer.play("Wall_slide")
		
		if on_left_wall:
			$Sprite2D.flip_h = true
		elif on_right_wall:
			$Sprite2D.flip_h = false
			
	elif not is_on_floor():
		if velocity.y < 0:
			$AnimationPlayer.play("Jump")
		else:
			$AnimationPlayer.play("Fall")
		
		if x_input < 0:
			$Sprite2D.flip_h = true
		elif x_input > 0:
			$Sprite2D.flip_h = false
			
	else:
		if x_input != 0:
			$AnimationPlayer.play("Run")
		else:
			$AnimationPlayer.play("Idle")
		
		if x_input < 0:
			$Sprite2D.flip_h = true
		elif x_input > 0:
			$Sprite2D.flip_h = false
	
	move_and_slide()
	player_death()
