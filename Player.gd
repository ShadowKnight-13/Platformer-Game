extends CharacterBody2D

const SPEED = 300.0
const JUMP_HEIGHT: float = -500.0
const JUMP_CUT_MULTIPLIER: float = 0.2
const FRICTION: float = 22.5

const GRAVITY_NORMAL: float = 16
const GRAVITY_WALL_SLIDE: float = 100.5
const WALL_JUMP_PUSH_FORCE: float = 600.0

# === DASH SLIDE CONSTANTS ===
const DASH_SPEED: float = 700.0  # Speed boost during dash
const DASH_DURATION: float = 0.4  # How long the dash lasts
const DASH_COOLDOWN: float = 0.8  # Time before you can dash again

var wall_stick_time := 0.0
const WALL_STICK_DURATION := 0.5

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.15

var health = 3
var is_wall_jumping := false
var is_jumping := false

# === DASH SLIDE VARIABLES ===
var is_dashing := false
var dash_time_remaining := 0.0
var dash_cooldown_remaining := 0.0
var dash_direction := 1.0  # Store direction we're dashing in

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

func _ready():
	# Store the original collision shape for restoring after dash
	pass

func _physics_process(delta):
	var x_input = Input.get_axis("move_left", "move_right")
	
	# Update dash cooldown
	if dash_cooldown_remaining > 0:
		dash_cooldown_remaining -= delta
	
	# === DASH SLIDE LOGIC ===
	if is_dashing:
		dash_time_remaining -= delta
		
		if dash_time_remaining <= 0:
			# Dash ended
			is_dashing = false
			dash_cooldown_remaining = DASH_COOLDOWN
			# Restore collision height
			$CollisionShape2D.scale.y = 1.0
			$CollisionShape2D.position.y = 0
		else:
			# Continue dashing
			velocity.x = dash_direction * DASH_SPEED
			# Optional: slight downward force to stay grounded
			if is_on_floor():
				velocity.y = 10
	
	# Initiate dash
	if Input.is_action_just_pressed("dash") and is_on_floor() and not is_dashing and dash_cooldown_remaining <= 0:
		is_dashing = true
		dash_time_remaining = DASH_DURATION
		
		# Determine dash direction (use current facing or input)
		if x_input != 0:
			dash_direction = sign(x_input)
		else:
			# If no input, dash in the direction player is facing
			dash_direction = 1.0 if not $Sprite2D.flip_h else -1.0
		
		# Reduce collision height by half
		$CollisionShape2D.scale.y = 0.5
		$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25  # Adjust position so it stays grounded
		
		velocity.x = dash_direction * DASH_SPEED
	
	# Skip normal movement logic if dashing
	if not is_dashing:
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
				is_jumping = true
				wall_stick_time = 0.0
		else:
			wall_stick_time = 0.0
			
			# Apply normal gravity
			if not is_on_floor():
				velocity.y += GRAVITY_NORMAL
		
		# Ground jump
		if is_on_floor():
			is_jumping = false
			
			if Input.is_action_just_pressed("jump"):
				velocity.y = JUMP_HEIGHT
				is_jumping = true
		
		# Variable jump height
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
	else:
		# === DASHING ANIMATION ===
		$AnimationPlayer.play("Slide")
		# Maintain sprite direction during dash
		$Sprite2D.flip_h = dash_direction < 0
	
	move_and_slide()
	player_death()
