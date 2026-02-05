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

# === STEP-UP CONSTANTS ===
const STEP_UP_MAX_HEIGHT: float = 70.0
const STEP_UP_CHECK_DISTANCE: float = 10.0

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
var facing_direction := 1.0  # Track which way player is facing (1 = right, -1 = left)

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
	print("[FRAME] is_on_floor: ", is_on_floor(), " | was_on_floor_last_frame: ", was_on_floor_last_frame, " | is_jumping: ", is_jumping)

	if is_on_floor() and not was_on_floor_last_frame:
		print("[LANDING] ✅ LANDING DETECTED - Resetting jump flags")
		is_jumping = false
		is_dash_jumping = false
	# Clamp horizontal velocity to normal speed on landing
	if abs(velocity.x) > SPEED * 1.1:  # Allow small buffer
		velocity.x = sign(velocity.x) * SPEED
	print("Player landed! Reset jump flags.")
	# Restore collision if it was waiting
	if needs_collision_restore:
		$CollisionShape2D.scale.y = 1.0
		$CollisionShape2D.position.y = 0
		needs_collision_restore = false
		print("Collision shape restored on landing!")

	# ADDITIONAL SAFETY: Always reset jumping flag if on floor
	if is_on_floor() and is_jumping:
		print("[SAFETY] On floor but is_jumping still true - resetting!")
		is_jumping = false
		is_dash_jumping = false
		
		# Clamp horizontal velocity to normal speed on landing
		if abs(velocity.x) > SPEED * 1.1:  # Allow small buffer
			velocity.x = sign(velocity.x) * SPEED
		print("Player landed! Reset jump flags.")
		# Restore collision if it was waiting
		if needs_collision_restore:
			$CollisionShape2D.scale.y = 1.0
			$CollisionShape2D.position.y = 0
			needs_collision_restore = false
			print("Collision shape restored on landing!")
	
	
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
	
				# ALWAYS restore collision shape when dash ends
				$CollisionShape2D.scale.y = 1.0
				$CollisionShape2D.position.y = 0
				needs_collision_restore = false  # No longer needed
				print("Dash ended - collision restored")
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
		# Check if we're on a wall FIRST (highest priority)
		if is_stuck_to_wall and is_on_wall() and not is_on_floor():
			# WALL DASH - Automatically dash away from wall
			is_dashing = true
			is_air_dive = true
			air_dash_horizontal_timer = 0.0
			dash_time_remaining = DASH_DURATION
			wall_stick_time = 0.0
			is_stuck_to_wall = false  # Release from wall
			
			# Dash AWAY from the wall automatically
			var wall_normal = get_wall_normal()
			dash_direction = sign(wall_normal.x)
			
			# Reduce collision height for dash
			$CollisionShape2D.scale.y = 0.5
			$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
			
			# Set velocities for horizontal dash away from wall
			velocity.x = dash_direction * DASH_SPEED
			velocity.y = 0  # Start horizontal
			
			print("=== WALL DASH INITIATED ===")
			
		elif is_on_floor():
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
				dash_direction = facing_direction
			
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
		var on_left_wall = is_on_wall() and wall_normal.x > 0
		var on_right_wall = is_on_wall() and wall_normal.x < 0
		
		# Check if pressing AWAY from wall
		var pressing_away_from_wall = false
		if on_left_wall and x_input > 0:
			pressing_away_from_wall = true
		elif on_right_wall and x_input < 0:
			pressing_away_from_wall = true
		
		# Check if we JUST touched a wall (and should grab it)
		if is_on_wall() and not is_on_floor() and not is_stuck_to_wall and not pressing_away_from_wall:
			# Only grab if moving downward (falling) or just barely upward
			if velocity.y >= -100:  # Allow slight upward velocity
				is_stuck_to_wall = true
				wall_stick_time = 0.0
				print("=== GRABBED WALL ===")

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
		
		# Check if we should STOP sticking to wall (AFTER checking actions)
		# This way dash/jump take priority over manual release
		if is_stuck_to_wall and not is_wall_sliding:
			# Only release manually if NOT currently on wall OR pressing away OR on floor
			if pressing_away_from_wall or not is_on_wall() or is_on_floor():
				is_stuck_to_wall = false
				wall_stick_time = 0.0
				print("=== RELEASED WALL ===")
		
		# Apply gravity when NOT on wall
		if not is_wall_sliding:
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
				facing_direction = sign(x_input)  # Track facing direction
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
		$AnimationPlayer.play("Dash")
		# Maintain sprite direction during dash
		$Sprite2D.flip_h = dash_direction < 0
		facing_direction = dash_direction  # Update facing direction during dash
	
	print("9. Just before move_and_slide - velocity.y: ", velocity.y)
	move_and_slide()
	print("10. Just after move_and_slide - velocity.y: ", velocity.y)
	
	# === STEP-UP MECHANIC ===
	# Check if we should step up a small obstacle
	# Works during normal movement AND dash/slide
	print("[DEBUG] is_on_floor: ", is_on_floor(), " | is_jumping: ", is_jumping)

	var step_height = 0.0  # Declare OUTSIDE the if block

	if is_on_floor() and not is_jumping:
		print("[DEBUG] Calling check_for_step()")
		step_height = check_for_step(x_input)  # Now just assign, not declare
		print("[DEBUG] Step height returned: ", step_height)
	
	if step_height > 0:
		# Instantly move the player up by the step height (pixel-perfect style)
		position.y -= step_height
		print("✅ STEPPED UP ", step_height, " pixels")
	else:
		if not is_on_floor():
			print("[DEBUG] NOT calling step-up: not on floor")
		elif is_jumping:
			print("[DEBUG] NOT calling step-up: currently jumping")
	
	if is_dash_jumping:
		print("11. End of frame - still dash jumping, velocity.y: ", velocity.y, "\n")
	
	# Track floor state for next frame
	was_on_floor_last_frame = is_on_floor()
	
	player_death()

# Check if there's a step in front of the player and return the step height
func check_for_step(x_input: float) -> float:
	print("[STEP-UP] === FUNCTION CALLED ===")
	
	# Only check for steps when on the ground
	if not is_on_floor():
		print("[STEP-UP] ❌ Not on floor")
		return 0.0
	
	
	print("[STEP-UP] x_input: ", x_input, " | facing_direction: ", facing_direction, " | is_dashing: ", is_dashing)
	
	# Player must be pressing toward the direction they're facing OR dashing
	var trying_to_move_forward = false
	
	if is_dashing:
		trying_to_move_forward = true
		print("[STEP-UP] ✅ Dashing - allowing step-up")
	else:
		if abs(x_input) > 0.1:
			if sign(x_input) == sign(facing_direction):
				trying_to_move_forward = true
				print("[STEP-UP] ✅ Pressing toward facing direction")
			else:
				print("[STEP-UP] ❌ Pressing AWAY from facing direction")
		else:
			print("[STEP-UP] ❌ No input (x_input too small)")
	
	if not trying_to_move_forward:
		print("[STEP-UP] ❌ Not moving forward - returning 0")
		return 0.0
	
	print("[STEP-UP] Checking for obstacle ahead...")
	
	# Use the direction the player is facing
	var step_direction = facing_direction
	
	# Create a raycast to check for obstacles ahead
	var space_state = get_world_2d().direct_space_state
	
	# Get the collision shape size
	var collision_shape = $CollisionShape2D.shape
	var player_width = collision_shape.size.x / 2.0
	var player_height = collision_shape.size.y
	
	print("[STEP-UP] Player width: ", player_width, " | Player height: ", player_height)
	print("[STEP-UP] Player position: ", global_position)
	
	# Check for wall ahead at player's FEET level
	# Start from the front edge AND near the bottom
	var feet_offset = player_height * 0.4  # Slightly above the very bottom to avoid floor
	var ray_start = global_position + Vector2(step_direction * player_width, feet_offset)
	var ray_end = ray_start + Vector2(step_direction * STEP_UP_CHECK_DISTANCE, 0)
	
	print("[STEP-UP] Raycast from: ", ray_start, " to: ", ray_end)
	print("[STEP-UP] Distance: ", (ray_end - ray_start).length(), " pixels")
	
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [self]
	query.collision_mask = 2  # Only check "World" layer (layer 2)
	
	var result = space_state.intersect_ray(query)
	
	# If we hit a wall
	if result:
		print("[STEP-UP] ✅ HIT OBSTACLE at: ", result.position)
		
		# Now check how high the wall is by casting a ray downward from above
		var check_height = STEP_UP_MAX_HEIGHT
		var top_check_start = result.position + Vector2(step_direction * 2, -check_height)
		var top_check_end = result.position + Vector2(step_direction * 2, 0)
		
		print("[STEP-UP] Checking height - from: ", top_check_start, " to: ", top_check_end)
		
		var top_query = PhysicsRayQueryParameters2D.create(top_check_start, top_check_end)
		top_query.exclude = [self]
		top_query.collision_mask = 2
		
		var top_result = space_state.intersect_ray(top_query)
		
		if top_result:
			# Calculate the height of the step
			var step_height = top_result.position.y - global_position.y
			
			print("[STEP-UP] Player Y: ", global_position.y, " | Step top Y: ", top_result.position.y)
			print("[STEP-UP] Calculated step height: ", step_height, " | Max: ", STEP_UP_MAX_HEIGHT)
			
			# Only return valid step heights
			if step_height > 0 and step_height <= STEP_UP_MAX_HEIGHT:
				print("[STEP-UP] ✅✅✅ VALID STEP! Returning: ", step_height)
				return step_height
			else:
				print("[STEP-UP] ❌ Step invalid (too tall, too short, or negative)")
		else:
			print("[STEP-UP] ❌ No top surface found - obstacle might be too tall")
	else:
		print("[STEP-UP] ❌ No obstacle detected by raycast")
	
	return 0.0
