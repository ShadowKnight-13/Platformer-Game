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

func heal(amount: int = 1) -> void:
	health = mini(health + amount, 3)
	emit_signal("health_changed", health)

# NEW FUNCTION: Check if we're on a grippable wall
# Returns true only for layer 2 (World - Platforming)
# Returns false for layer 4 (World - Slippery Walls)
func is_on_grippable_wall() -> bool:
	# First check if we're touching any wall
	if not is_on_wall():
		return false
	
	# Check each collision to see if it's on the grippable layer
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		
		# Check if collider is on layer 2 (World - Platforming)
		# Bit 1 represents layer 2 (0-indexed, so layer 2 = bit 1)
		if collider.collision_layer & (1 << 1):
			return true
	
	# No grippable walls found
	return false

func _physics_process(delta):
	var x_input = Input.get_axis("move_left", "move_right")
	
	# Reset gravity skip flag at start of frame
	skip_gravity_this_frame = false
	
	# Update dash cooldown
	if dash_cooldown_remaining > 0:
		dash_cooldown_remaining -= delta
	
	# === RESET JUMP FLAGS ON LANDING ===

	if is_on_floor() and not was_on_floor_last_frame:
		is_jumping = false
		is_dash_jumping = false
	# Clamp horizontal velocity to normal speed on landing
	if abs(velocity.x) > SPEED * 1.1:  # Allow small buffer
		velocity.x = sign(velocity.x) * SPEED
	# Restore collision if it was waiting
	if needs_collision_restore:
		$CollisionShape2D.scale.y = 1.0
		$CollisionShape2D.position.y = 0
		needs_collision_restore = false

	# ADDITIONAL SAFETY: Always reset jumping flag if on floor
	if is_on_floor() and is_jumping:
		is_jumping = false
		is_dash_jumping = false
		
		# Clamp horizontal velocity to normal speed on landing
		if abs(velocity.x) > SPEED * 1.1:  # Allow small buffer
			velocity.x = sign(velocity.x) * SPEED
		# Restore collision if it was waiting
		if needs_collision_restore:
			$CollisionShape2D.scale.y = 1.0
			$CollisionShape2D.position.y = 0
			needs_collision_restore = false
	
	
	# Ground jump
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not is_dashing:
			velocity.y = JUMP_HEIGHT
			is_jumping = true
			is_dash_jumping = false  # Normal jumps are NOT dash jumps
			skip_gravity_this_frame = true  # Don't apply gravity on jump frame
	
	# === DASH/DIVE LOGIC ===
	if is_dashing:
		
		# === CHECK FOR DASH JUMP FIRST - BEFORE applying dash movement ===
		if Input.is_action_just_pressed("jump") and is_on_floor():
			# Jump from dash - POWERFUL combined momentum!
			is_dashing = false
			is_air_dive = false
			air_dash_horizontal_timer = 0.0
			dash_cooldown_remaining = DASH_COOLDOWN
			
			# Restore collision height immediately (we're jumping from ground)
			$CollisionShape2D.scale.y = 1.0
			$CollisionShape2D.position.y = 0
			needs_collision_restore = false
			
			# POWERFUL dash jump with boosted height AND speed
			velocity.y = JUMP_HEIGHT * DASH_JUMP_HEIGHT_MULTIPLIER  # 30% higher jump!
			velocity.x = dash_direction * DASH_SPEED * DASH_JUMP_SPEED_MULTIPLIER  # 20% faster!
			
			is_jumping = true
			is_dash_jumping = true  # Mark as dash jump
			skip_gravity_this_frame = true  # Don't apply gravity this frame!
			
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
					velocity.y += GRAVITY_NORMAL
	
	# === INITIATE DASH/DIVE ===
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_remaining <= 0:
		# Check if we're on a GRIPPABLE wall FIRST (highest priority)
		# UPDATED: Use is_on_grippable_wall() instead of is_on_wall()
		if is_stuck_to_wall and is_on_grippable_wall() and not is_on_floor():
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
	
	# Skip normal movement logic if dashing
	if not is_dashing:
		
		# Determine which wall we're on
		var wall_normal = get_wall_normal()
		var on_left_wall = is_on_grippable_wall() and wall_normal.x > 0  # UPDATED
		var on_right_wall = is_on_grippable_wall() and wall_normal.x < 0  # UPDATED
		
		# Check if pressing AWAY from wall
		var pressing_away_from_wall = false
		if on_left_wall and x_input > 0:
			pressing_away_from_wall = true
		elif on_right_wall and x_input < 0:
			pressing_away_from_wall = true
		
		# Check if we JUST touched a GRIPPABLE wall (and should grab it)
		# UPDATED: Use is_on_grippable_wall() instead of is_on_wall()
		if is_on_grippable_wall() and not is_on_floor() and not is_stuck_to_wall and not pressing_away_from_wall:
			# Only grab if moving downward (falling) or just barely upward
			if velocity.y >= -100:  # Allow slight upward velocity
				is_stuck_to_wall = true
				wall_stick_time = 0.0

		# === WALL STICK & SLIDE PHYSICS ===
		var is_wall_sliding = false

		# Apply wall stick/slide physics if stuck ON A GRIPPABLE WALL
		# UPDATED: Use is_on_grippable_wall() instead of is_on_wall()
		if is_stuck_to_wall and is_on_grippable_wall() and not is_on_floor():
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
				is_dash_jumping = false  # Wall jumps are NOT dash jumps
				skip_gravity_this_frame = true  # Don't apply gravity on jump frame
				wall_stick_time = 0.0
				is_stuck_to_wall = false  # Release from wall
		
		# Check if we should STOP sticking to wall (AFTER checking actions)
		# This way dash/jump take priority over manual release
		# UPDATED: Use is_on_grippable_wall() instead of is_on_wall()
		if is_stuck_to_wall and not is_wall_sliding:
			# Only release manually if NOT currently on wall OR pressing away OR on floor
			if pressing_away_from_wall or not is_on_grippable_wall() or is_on_floor():
				is_stuck_to_wall = false
				wall_stick_time = 0.0

		
		# Apply gravity when NOT on wall
		if not is_wall_sliding:
			wall_stick_time = 0.0
			
			# Apply normal gravity - BUT NOT on jump frames
			if not is_on_floor() and not skip_gravity_this_frame:
				velocity.y += GRAVITY_NORMAL
		
		# === VARIABLE JUMP HEIGHT ===
		# Only cut normal jumps, not dash jumps
		if Input.is_action_just_released("jump") and is_jumping and velocity.y < 0:
			if not is_dash_jumping:
				velocity.y *= JUMP_CUT_MULTIPLIER
		
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
	
	move_and_slide()
	
	# === STEP-UP MECHANIC ===
	# Check if we should step up a small obstacle
	# Works during normal movement AND dash/slide

	var step_height = 0.0  # Declare OUTSIDE the if block

	if is_on_floor() and not is_jumping:
		step_height = check_for_step(x_input)  # Now just assign, not declare
	
	if step_height > 0:
		# Instantly move the player up by the step height (pixel-perfect style)
		position.y -= step_height
	
	# Track floor state for next frame
	was_on_floor_last_frame = is_on_floor()
	
	player_death()

# Check if there's a step in front of the player and return the step height
func check_for_step(x_input: float) -> float:
	
	# Only check for steps when on the ground
	if not is_on_floor():
		return 0.0
	# Player must be pressing toward the direction they're facing OR dashing
	var trying_to_move_forward = false
	
	if is_dashing:
		trying_to_move_forward = true
	else:
		if abs(x_input) > 0.1:
			if sign(x_input) == sign(facing_direction):
				trying_to_move_forward = true
	
	if not trying_to_move_forward:
		return 0.0
	
	# Use the direction the player is facing
	var step_direction = facing_direction
	
	# Create a raycast to check for obstacles ahead
	var space_state = get_world_2d().direct_space_state
	
	# Get the collision shape size
	var collision_shape = $CollisionShape2D.shape
	var player_width = collision_shape.size.x / 2.0
	var player_height = collision_shape.size.y
	
	# Check for wall ahead at player's FEET level
	# Start from the front edge AND near the bottom
	var feet_offset = player_height * 0.4  # Slightly above the very bottom to avoid floor
	var ray_start = global_position + Vector2(step_direction * player_width, feet_offset)
	var ray_end = ray_start + Vector2(step_direction * STEP_UP_CHECK_DISTANCE, 0)
	
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [self]
	query.collision_mask = 2  # Only check "World" layer (layer 2)
	
	var result = space_state.intersect_ray(query)
	
	# If we hit a wall
	if result:
		
		# Now check how high the wall is by casting a ray downward from above
		var check_height = STEP_UP_MAX_HEIGHT
		var top_check_start = result.position + Vector2(step_direction * 2, -check_height)
		var top_check_end = result.position + Vector2(step_direction * 2, 0)
		
		var top_query = PhysicsRayQueryParameters2D.create(top_check_start, top_check_end)
		top_query.exclude = [self]
		top_query.collision_mask = 2
		
		var top_result = space_state.intersect_ray(top_query)
		
		if top_result:
			# Calculate the height of the step
			var step_height = top_result.position.y - global_position.y
			
			# Only return valid step heights
			if step_height > 0 and step_height <= STEP_UP_MAX_HEIGHT:
				return step_height
	
	return 0.0


# This variable will store the object we are currently standing near
var current_interactable = null

func _input(event):
	# Check if the "interact" button was pressed AND we are near something
	if event.is_action_pressed("interact") and current_interactable != null:
		current_interactable.interact()

# Connect the Area2D 'area_entered' signal to this function
func _on_interaction_area_area_entered(area):
	# If the area we entered has an 'interact' function, save it
	if area.has_method("interact"):
		current_interactable = area

# Connect the Area2D 'area_exited' signal to this function
func _on_interaction_area_area_exited(area):
	# If we walk away, forget the object
	if area == current_interactable:
		current_interactable = null
