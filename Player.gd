extends CharacterBody2D

const SPEED = 300.0
const JUMP_HEIGHT: float = -500.0
const JUMP_CUT_MULTIPLIER: float = 0.2
const FRICTION: float = 22.5

const GRAVITY_NORMAL: float = 16
const GRAVITY_WALL_SLIDE: float = 100.5
const WALL_JUMP_PUSH_FORCE: float = 600.0

# === DASH SLIDE CONSTANTS ===
const DASH_SPEED: float = 700.0
const DASH_DURATION: float = 0.4
const DASH_COOLDOWN: float = 0.8
const DIVE_VERTICAL_BOOST: float = 200.0
const AIR_DASH_HORIZONTAL_TIME: float = 0.15
const DASH_JUMP_SPEED_MULTIPLIER: float = 1.2
const DASH_JUMP_HEIGHT_MULTIPLIER: float = 1.3
const DASH_JUMP_AIR_CONTROL: float = 0.3

var wall_stick_time := 0.0
const WALL_STICK_DURATION := 0.5

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.15
var is_stuck_to_wall := false

var health = 3
var is_wall_jumping := false
var is_jumping := false
var is_dash_jumping := false
var was_on_floor_last_frame := false
var skip_gravity_this_frame := false
var needs_collision_restore := false

# === DASH SLIDE VARIABLES ===
var is_dashing := false
var dash_time_remaining := 0.0
var dash_cooldown_remaining := 0.0
var dash_direction := 1.0
var is_air_dive := false
var air_dash_horizontal_timer := 0.0

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
	
	var velocity_y_at_start = velocity.y  # Track initial value
	
	# Reset gravity skip flag at start of frame
	skip_gravity_this_frame = false
	
	# Update dash cooldown
	if dash_cooldown_remaining > 0:
		dash_cooldown_remaining -= delta
	
	# === RESET JUMP FLAGS ON LANDING ===
	# Check if we just landed this frame - MOVED TO TOP
	if is_on_floor() and not was_on_floor_last_frame:
		is_jumping = false
		is_dash_jumping = false
		# Clamp horizontal velocity to normal speed on landing
		if abs(velocity.x) > SPEED * 1.1:  # Allow small buffer
			velocity.x = sign(velocity.x) * SPEED
		print("Player landed! Reset jump flags.")
	
	# Ground jump
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not is_dashing:
			velocity.y = JUMP_HEIGHT
			is_jumping = true
			is_dash_jumping = false  # Normal jumps are NOT dash jumps
			skip_gravity_this_frame = true  # Don't apply gravity on jump frame
			print("Normal jump: velocity.y = ", velocity.y)
	
	if velocity.y != velocity_y_at_start:
		print("!!! velocity.y changed in collision restore: ", velocity_y_at_start, " -> ", velocity.y)
	
	# === DASH/DIVE LOGIC ===
	if is_dashing:
		var before_dash_logic = velocity.y
		
		# === CHECK FOR DASH JUMP FIRST - BEFORE applying dash movement ===
		if Input.is_action_just_pressed("jump") and is_on_floor():
			print("\n====== DASH JUMP FRAME ======")
			print("1. Before setting velocity.y: ", velocity.y)
			
			# Jump from dash - POWERFUL combined momentum!
			is_dashing = false
			is_air_dive = false
			air_dash_horizontal_timer = 0.0
			dash_cooldown_remaining = DASH_COOLDOWN
			
			# Restore collision height immediately (we're jumping from ground)
			$CollisionShape2D.scale.y = 1.0
			$CollisionShape2D.position.y = 0
			needs_collision_restore = false
			
			print("2. Calculating: ", JUMP_HEIGHT, " * ", DASH_JUMP_HEIGHT_MULTIPLIER, " = ", JUMP_HEIGHT * DASH_JUMP_HEIGHT_MULTIPLIER)
			
			# POWERFUL dash jump with boosted height AND speed
			velocity.y = JUMP_HEIGHT * DASH_JUMP_HEIGHT_MULTIPLIER  # 30% higher jump!
			velocity.x = dash_direction * DASH_SPEED * DASH_JUMP_SPEED_MULTIPLIER  # 20% faster!
			
			print("3. After setting velocity.y: ", velocity.y)
			print("4. After setting velocity.x: ", velocity.x)
			
			is_jumping = true
			is_dash_jumping = true  # Mark as dash jump
			skip_gravity_this_frame = true  # Don't apply gravity this frame!
			
			print("5. is_dash_jumping: ", is_dash_jumping)
			print("6. skip_gravity_this_frame: ", skip_gravity_this_frame)
			print("7. is_dashing: ", is_dashing)
			
		elif Input.is_action_just_pressed("jump") and is_air_dive:
			# Can't jump during air dive (optional)
			pass
		else:
			# Not jumping, continue normal dash behavior
			dash_time_remaining -= delta
			
			if dash_time_remaining <= 0:
				# Dash ended
				is_dashing = false
				is_air_dive = false
				air_dash_horizontal_timer = 0.0
				dash_cooldown_remaining = DASH_COOLDOWN
				
				# Only restore collision if on ground, otherwise mark for later
				if is_on_floor():
					$CollisionShape2D.scale.y = 1.0
					$CollisionShape2D.position.y = 0
				else:
					needs_collision_restore = true
			else:
				# Continue dashing
				velocity.x = dash_direction * DASH_SPEED
				
				if is_air_dive:
					# === AIR DASH HORIZONTAL PHASE ===
					if air_dash_horizontal_timer < AIR_DASH_HORIZONTAL_TIME:
						# Horizontal phase - maintain velocity, no gravity
						air_dash_horizontal_timer += delta
						velocity.y = 0  # Keep horizontal during this phase
					else:
						# Horizontal phase over - apply gravity
						velocity.y += GRAVITY_NORMAL
						
						# Add extra downward momentum for dive feel
						if velocity.y < DIVE_VERTICAL_BOOST:
							velocity.y += GRAVITY_NORMAL * 2  # fall faster during dive
				else:
					# Ground dash - apply gravity normally
					print("!!! Ground dash applying gravity: ", velocity.y, " + ", GRAVITY_NORMAL)
					velocity.y += GRAVITY_NORMAL
					print("!!! After gravity: ", velocity.y)
		
		if velocity.y != before_dash_logic and not Input.is_action_just_pressed("jump"):
			print("!!! velocity.y changed in dash logic: ", before_dash_logic, " -> ", velocity.y)
	
	# === INITIATE DASH/DIVE ===
	var before_initiate = velocity.y
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_remaining <= 0:
		if is_on_floor():
			# Ground dash - requires horizontal movement
			if abs(x_input) > 0.1:  # Must be moving horizontally
				is_dashing = true
				is_air_dive = false
				air_dash_horizontal_timer = 0.0
				dash_time_remaining = DASH_DURATION
				
				# Use input direction for dash
				dash_direction = sign(x_input)
				
				# Reduce collision height by half
				$CollisionShape2D.scale.y = 0.5
				$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
				
				velocity.x = dash_direction * DASH_SPEED
				velocity.y = 10  # Small downward nudge to stay grounded
		else:
			# Air dive - no horizontal movement required
			is_dashing = true
			is_air_dive = true
			air_dash_horizontal_timer = 0.0  # Reset horizontal phase timer
			dash_time_remaining = DASH_DURATION
			
			# Determine dive direction (use input, or facing direction if no input)
			if abs(x_input) > 0.1:
				dash_direction = sign(x_input)
			else:
				# Dive in facing direction if no input
				dash_direction = 1.0 if not $Sprite2D.flip_h else -1.0
			
			# Reduce collision height
			$CollisionShape2D.scale.y = 0.5
			$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
			
			# Set dive velocities - start horizontal
			velocity.x = dash_direction * DASH_SPEED
			velocity.y = 0  # Start perfectly horizontal
	
	if velocity.y != before_initiate:
		print("!!! velocity.y changed in initiate dash: ", before_initiate, " -> ", velocity.y)
	
	# Skip normal movement logic if dashing
	if not is_dashing:
		var before_normal_movement = velocity.y
		
		# Determine which wall we're on
		var wall_normal = get_wall_normal()
		var on_left_wall = wall_normal.x > 0
		var on_right_wall = wall_normal.x < 0

		# Check if player is pressing INTO the wall (for initial grab)
		var pressing_into_wall = false
		if on_left_wall and x_input < 0:
			pressing_into_wall = true
		elif on_right_wall and x_input > 0:
			pressing_into_wall = true

		# Check if player is pressing AWAY from the wall (to release)
		var pressing_away_from_wall = false
		if on_left_wall and x_input > 0:
			pressing_away_from_wall = true
		elif on_right_wall and x_input < 0:
			pressing_away_from_wall = true

		# === WALL STICK STATE MANAGEMENT ===
		# Check if we should START sticking to wall
		if is_on_wall() and not is_on_floor() and pressing_into_wall and not is_stuck_to_wall:
			# Initial grab - player pressed into wall
			is_stuck_to_wall = true
			wall_stick_time = 0.0
			print("=== GRABBED WALL ===")

		# Check if we should STOP sticking to wall
		if is_stuck_to_wall:
			# Release if player presses away from wall OR if no longer touching wall
			if pressing_away_from_wall or not is_on_wall() or is_on_floor():
				is_stuck_to_wall = false
				wall_stick_time = 0.0
				print("=== RELEASED WALL ===")

		# === WALL STICK & SLIDE PHYSICS ===
		var is_wall_sliding = false

		# Apply wall stick/slide physics if stuck
		if is_stuck_to_wall and is_on_wall() and not is_on_floor():
			is_wall_sliding = true
	
			if wall_stick_time < WALL_STICK_DURATION:
				wall_stick_time += delta
				print("!!! Wall stick setting velocity.y to 0")
				velocity.y = 0
			else:
				print("!!! Wall slide setting velocity.y to ", GRAVITY_WALL_SLIDE)
				velocity.y = GRAVITY_WALL_SLIDE
	
		# Handle wall jump
			if Input.is_action_just_pressed("jump"):
				velocity.y = JUMP_HEIGHT
				velocity.x = wall_normal.x * WALL_JUMP_PUSH_FORCE
				wall_jump_lock = WALL_JUMP_LOCK_TIME
				is_wall_jumping = true
				is_jumping = true
				is_dash_jumping = false  # Wall jumps are NOT dash jumps
				skip_gravity_this_frame = true  # Don't apply gravity on jump frame
				wall_stick_time = 0.0
				is_stuck_to_wall = false  # Release from wall
				print("=== WALL JUMP - RELEASED WALL ===")
	
			# Handle wall dash
			elif Input.is_action_just_pressed("dash") and dash_cooldown_remaining <= 0:
				# Trigger air dash from wall
				is_dashing = true
				is_air_dive = true
				air_dash_horizontal_timer = 0.0
				dash_time_remaining = DASH_DURATION
				wall_stick_time = 0.0
				is_stuck_to_wall = false  # Release from wall
		
				# Dash AWAY from the wall
				dash_direction = sign(wall_normal.x)
		
				# Reduce collision height for dash
				$CollisionShape2D.scale.y = 0.5
				$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
		
				# Set velocities for horizontal dash away from wall
				velocity.x = dash_direction * DASH_SPEED
				velocity.y = 0  # Start horizontal
		
				print("=== WALL DASH - RELEASED WALL ===")
		else:
			wall_stick_time = 0.0
	
			# Apply normal gravity - BUT NOT on jump frames
			if not is_on_floor() and not skip_gravity_this_frame:
				print("!!! Applying normal gravity: ", velocity.y, " + ", GRAVITY_NORMAL, " (skip_gravity: ", skip_gravity_this_frame, ")")
				velocity.y += GRAVITY_NORMAL
				print("!!! After normal gravity: ", velocity.y)
				
				# Handle wall jump
				if Input.is_action_just_pressed("jump"):
					velocity.y = JUMP_HEIGHT
					velocity.x = wall_normal.x * WALL_JUMP_PUSH_FORCE
					wall_jump_lock = WALL_JUMP_LOCK_TIME
					is_wall_jumping = true
					is_jumping = true
					is_dash_jumping = false  # Wall jumps are NOT dash jumps
					skip_gravity_this_frame = true  # Don't apply gravity on jump frame
					wall_stick_time = 0.0

				# === NEW: Handle wall dash ===
				elif Input.is_action_just_pressed("dash") and dash_cooldown_remaining <= 0:
				# Trigger air dash from wall
					is_dashing = true
					is_air_dive = true
					air_dash_horizontal_timer = 0.0
					dash_time_remaining = DASH_DURATION
					wall_stick_time = 0.0  # Reset wall stick time
	
					# Dash AWAY from the wall (opposite direction of wall normal)
					# If on left wall (wall_normal.x > 0), dash right
					# If on right wall (wall_normal.x < 0), dash left
					dash_direction = sign(wall_normal.x)
	
					# Reduce collision height for dash
					$CollisionShape2D.scale.y = 0.5
					$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
	
					# Set velocities for horizontal dash away from wall
					velocity.x = dash_direction * DASH_SPEED
					velocity.y = 0  # Start horizontal
	
					print("Wall dash initiated! Direction: ", dash_direction)
				
			else:
				wall_stick_time = 0.0
			
			# Apply normal gravity - BUT NOT on jump frames
			if not is_on_floor() and not skip_gravity_this_frame:
				print("!!! Applying normal gravity: ", velocity.y, " + ", GRAVITY_NORMAL, " (skip_gravity: ", skip_gravity_this_frame, ")")
				velocity.y += GRAVITY_NORMAL
				print("!!! After normal gravity: ", velocity.y)
		
		# === VARIABLE JUMP HEIGHT ===
		# Only cut normal jumps, not dash jumps
		if Input.is_action_just_released("jump") and is_jumping and velocity.y < 0:
			if not is_dash_jumping:
				print("!!! Cutting normal jump: ", velocity.y, " * ", JUMP_CUT_MULTIPLIER)
				velocity.y *= JUMP_CUT_MULTIPLIER
				print("!!! After cut: ", velocity.y)
			else:
				print("8. Dash jump protected from cut")
		
		if velocity.y != before_normal_movement:
			print("!!! velocity.y changed in normal movement section: ", before_normal_movement, " -> ", velocity.y)
		
		# Horizontal movement (removed to keep output cleaner - doesn't affect velocity.y)
		if wall_jump_lock > 0.0:
			wall_jump_lock -= delta
			velocity.x = lerp(velocity.x, x_input * SPEED, 0.075)
		elif is_dash_jumping and not is_on_floor():
			if x_input != 0:
				velocity.x = lerp(velocity.x, x_input * SPEED, DASH_JUMP_AIR_CONTROL)
			else:
				velocity.x = lerp(velocity.x, 0.0, DASH_JUMP_AIR_CONTROL * 0.5)
		else:
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
		# === DASHING/DIVING ANIMATION ===
		$AnimationPlayer.play("Slide")
		# Maintain sprite direction during dash
		$Sprite2D.flip_h = dash_direction < 0
	
	print("9. Just before move_and_slide - velocity.y: ", velocity.y)
	move_and_slide()
	print("10. Just after move_and_slide - velocity.y: ", velocity.y)
	
	if is_dash_jumping:
		print("11. End of frame - still dash jumping, velocity.y: ", velocity.y, "\n")
	
	# Track floor state for next frame
	was_on_floor_last_frame = is_on_floor()
	
	player_death()
