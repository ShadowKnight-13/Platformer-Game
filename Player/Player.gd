extends CharacterBody2D

const SPEED = 300.0
const JUMP_HEIGHT: float = -500.0
const JUMP_CUT_MULTIPLIER: float = 0.2
const FRICTION: float = 22.5

const GRAVITY_NORMAL: float = 19
const GRAVITY_WALL_SLIDE: float = 100.5
const WALL_JUMP_PUSH_FORCE: float = 600.0

# === DASH SLIDE CONSTANTS ===
const DASH_SPEED: float = 700.0
const CROUCH_SPEED: float = 150.0
const DASH_DURATION: float = 0.3
const DASH_COOLDOWN: float = 0.8
const DIVE_VERTICAL_BOOST: float = 200.0
const AIR_DASH_HORIZONTAL_TIME: float = 0.15
const DASH_JUMP_SPEED_MULTIPLIER: float = 1.2
const DASH_JUMP_HEIGHT_MULTIPLIER: float = 1.3
const DASH_JUMP_AIR_CONTROL: float = 0.3

# === STEP-UP CONSTANTS ===
const STEP_UP_MAX_HEIGHT: float = 70.0
const STEP_UP_CHECK_DISTANCE: float = 10.0

# === LEDGE GRAB CONSTANTS ===
const LEDGE_GRAB_DISTANCE: float = 30.0  # Reduced - how far above player to check for ledge

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
var is_crouching := false

@onready var melee_hitbox: Area2D = $MeleeHitbox

#var debug_rays = []

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

func is_on_grippable_wall() -> bool:
	if not is_on_wall():
		return false
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		
		# Handle TileMapLayer using groups
		if collider is TileMapLayer:
			if collider.is_in_group("grippable_wall"):
				return true
			# Slippery or ungrouped - not grippable
			continue
				
		# Handle physics bodies (moving platforms, etc.)
		elif "collision_layer" in collider:
			# Check if on layer 2 (World - Platforming)
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
	
	# Melee attack input
	if Input.is_action_just_pressed("attack"):
		_try_attack()
	# === RESET JUMP FLAGS ON LANDING ===

	if is_on_floor() and not was_on_floor_last_frame:
		is_jumping = false
		is_dash_jumping = false
	# Clamp horizontal velocity to normal speed on landing
	if abs(velocity.x) > SPEED * 1.1:  # Allow small buffer
		velocity.x = sign(velocity.x) * SPEED
	# Restore collision if it was waiting and there's space
	if needs_collision_restore:
		if can_stand_up():
			$CollisionShape2D.scale.y = 1.0
			$CollisionShape2D.position.y = 0
			needs_collision_restore = false
			is_crouching = false
		else:
			# Entering crouch - maintain reduced collision
			$CollisionShape2D.scale.y = 0.5
			$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
			is_crouching = true
			needs_collision_restore = false

	# ADDITIONAL SAFETY: Always reset jumping flag if on floor
	if is_on_floor() and is_jumping:
		is_jumping = false
		is_dash_jumping = false
		
		# Clamp horizontal velocity to normal speed on landing
		if abs(velocity.x) > SPEED * 1.1:  # Allow small buffer
			velocity.x = sign(velocity.x) * SPEED
		# Restore collision if it was waiting and there's space
		if needs_collision_restore:
			if can_stand_up():
				$CollisionShape2D.scale.y = 1.0
				$CollisionShape2D.position.y = 0
				needs_collision_restore = false
				is_crouching = false
			else:
				# Entering crouch - maintain reduced collision
				$CollisionShape2D.scale.y = 0.5
				$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
				is_crouching = true
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
	
				# Only restore collision shape if there's space above
				if can_stand_up():
					$CollisionShape2D.scale.y = 1.0
					$CollisionShape2D.position.y = 0
					needs_collision_restore = false
					is_crouching = false
				else:
					# No space to stand — enter crouch state
					# CRITICAL: Keep the collision shape at reduced height
					$CollisionShape2D.scale.y = 0.5
					$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
					is_crouching = true
					needs_collision_restore = false
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
				
				# OPTIONAL: keep player grounded during dash
				if velocity.y < 10:
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
		elif is_crouching:
			# Check each frame if space has opened up to stand
			if can_stand_up():
				$CollisionShape2D.scale.y = 1.0
				$CollisionShape2D.position.y = 0
				needs_collision_restore = false
				is_crouching = false
			else:
				# MAKE SURE collision stays reduced while crouching
				$CollisionShape2D.scale.y = 0.5
				$CollisionShape2D.position.y = $CollisionShape2D.shape.size.y * 0.25
			# Move at reduced crouch speed
			if x_input != 0:
				velocity.x = lerp(velocity.x, x_input * CROUCH_SPEED, 0.15)
				facing_direction = sign(x_input)
			else:
				velocity.x = move_toward(velocity.x, 0, FRICTION)
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
				
		elif is_crouching:
			$AnimationPlayer.play("Dash")
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
	_update_attack_timers(delta)
	_update_melee_hitbox_position()
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
	
	# === LEDGE GRAB MECHANIC ===
	# Check for ledge grab when in the air and touching a wall
	# === LEDGE GRAB MECHANIC ===
# Check for ledge grab when in the air and touching a wall
	if not is_on_floor() and is_on_wall():
		var ledge_data = check_for_ledge()
		if ledge_data != Vector2.ZERO:
		# Teleport to ledge position
			global_position = ledge_data
			velocity.y = 0  # Cancel vertical velocity
		# Release from wall if stuck
			is_stuck_to_wall = false
			wall_stick_time = 0.0
	
	# Track floor state for next frame
	was_on_floor_last_frame = is_on_floor()
	
	player_death()

func can_stand_up() -> bool:
	if $CollisionShape2D.scale.y >= 1.0:
		return true
	
	var space_state = get_world_2d().direct_space_state
	var collision_shape = $CollisionShape2D.shape
	var player_height = collision_shape.size.y
	
	# Current height is 0.5 scale; full height is 1.0 scale
	var height_difference = player_height * 0.5  # The amount we're adding
	
	# Check from current top of collision to where new top would be
	var ray_start = global_position - Vector2(0, player_height * 0.25)  # Current top
	var ray_end = ray_start - Vector2(0, height_difference + 5.0)  # Add small buffer
	
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [self]
	query.collision_mask = 2  # World layer
	
	var result = space_state.intersect_ray(query)
	
	var can_stand = result.is_empty()
	var debug_color = Color.GREEN if can_stand else Color.RED
	debug_rays.append({
		"type": "line",
		"start": ray_start,
		"end": ray_end if can_stand else result.position,
		"color": debug_color
	})
	
	return can_stand

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
			# Found the top! Calculate step height
			var step_top_y = top_result.position.y
			var player_bottom_y = global_position.y + feet_offset
			
			var step_height_measured = player_bottom_y - step_top_y
			
			# Only step up if it's within our max height AND positive
			if step_height_measured > 0 and step_height_measured <= STEP_UP_MAX_HEIGHT:
				return step_height_measured
	
	return 0.0


func check_for_ledge() -> Vector2:
	#debug_rays.clear()  # Clear previous frame's debug data
	
	if not is_on_wall():
		return Vector2.ZERO
	
	var space_state = get_world_2d().direct_space_state
	var wall_normal = get_wall_normal()
	
	# Direction INTO the wall (opposite of normal)
	var into_wall_direction = -wall_normal.x
	
	# Get collision shape info
	var collision_shape = $CollisionShape2D.shape
	var player_width = collision_shape.size.x / 2.0
	var player_height = collision_shape.size.y / 2.0
	
	# Start checking from the BOTTOM of the player (feet level)
	var player_bottom_y = global_position.y + player_height
	
	# Check upward in smaller increments for better detection
	for i in range(6):
		var check_offset = i * 5.0
		var check_y = player_bottom_y - check_offset
		
		if check_offset > LEDGE_GRAB_DISTANCE:
			break
		
		# Check if there's still a wall at this height
		# Cast from player position TOWARD the wall
		var wall_check_start = Vector2(global_position.x, check_y)
		var wall_check_end = wall_check_start + Vector2(into_wall_direction * 20, 0)
		
		# Store debug info
		#debug_rays.append({"type": "line", "start": wall_check_start, "end": wall_check_end, "color": Color.YELLOW})
		
		var wall_query = PhysicsRayQueryParameters2D.create(wall_check_start, wall_check_end)
		wall_query.exclude = [self]
		wall_query.collision_mask = 2
		
		var wall_result = space_state.intersect_ray(wall_query)
		
		# If we DON'T hit a wall at this height, the wall has ended - check for floor
		if not wall_result:
			# Now check if there's a floor where the wall used to be
			# Cast downward from where the wall check ended (into the wall area)
			var floor_check_start = wall_check_end  # Start from where wall check ended
			var floor_check_end = floor_check_start + Vector2(0, 50)
			
			# Store debug info
			#debug_rays.append({"type": "line", "start": floor_check_start, "end": floor_check_end, "color": Color.GREEN})
			
			var floor_query = PhysicsRayQueryParameters2D.create(floor_check_start, floor_check_end)
			floor_query.exclude = [self]
			floor_query.collision_mask = 2
			
			var floor_result = space_state.intersect_ray(floor_query)
			
			if floor_result:
				# Store debug info
				#debug_rays.append({"type": "circle", "pos": floor_result.position, "color": Color.RED})
				
				# Found a valid ledge! Return position to teleport to
				var teleport_pos = Vector2(
					floor_result.position.x,
					floor_result.position.y - player_height - 2
				)
				return teleport_pos
	
	return Vector2.ZERO

func _process(_delta):
	debug_rays.clear()
	queue_redraw()
	
	# DEBUG: Update ColorRect to match collision shape size
	if OS.is_debug_build() and has_node("ColorRect") and has_node("CollisionShape2D"):
		var color_rect = $ColorRect
		var collision = $CollisionShape2D
		var shape = collision.shape as RectangleShape2D
		
		if shape:
			# Make it visible for debugging
			color_rect.visible = true
			
			# Calculate the actual size based on shape size and scale
			var actual_width = shape.size.x * collision.scale.x
			var actual_height = shape.size.y * collision.scale.y
			
			# Update ColorRect size (centered around origin)
			color_rect.offset_left = -actual_width / 2
			color_rect.offset_right = actual_width / 2
			color_rect.offset_top = -actual_height / 2 + collision.position.y
			color_rect.offset_bottom = actual_height / 2 + collision.position.y
			
			# Optional: Change color based on state for better debugging
			if is_crouching:
				color_rect.color = Color(1, 0.5, 0, 0.5)  # Orange when crouching
			elif is_dashing:
				color_rect.color = Color(1, 0, 0, 0.5)  # Red when dashing
			else:
				color_rect.color = Color(0.2, 0.6, 1, 0.5)  # Blue normally

func _draw():
	# Draw all stored debug rays
	#for ray in debug_rays:
		#if ray.type == "line":
			#draw_line(ray.start - global_position, ray.end - global_position, ray.color, 2.0)
		#elif ray.type == "circle":
			#draw_circle(ray.pos - global_position, 5, ray.color)

var is_attacking: bool = false
var attack_duration: float = 0.18
var attack_cooldown: float = 0.25
var _attack_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0

var melee_offset := Vector2(40, 0) #this can change to match hitbox

func _try_attack() -> void:
	if is_attacking or _attack_cooldown_timer > 0.0 or is_dashing:
		return

	is_attacking = true
	_attack_timer = attack_duration
	_attack_cooldown_timer = attack_cooldown

	print("Attack started")

	melee_hitbox.monitoring = true
	melee_hitbox.monitorable = true

	if $AnimationPlayer.has_animation("Attack"):
		$AnimationPlayer.play("Attack")


func _update_attack_timers(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

	if is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			is_attacking = false
			melee_hitbox.monitoring = false
			melee_hitbox.monitorable = false


func _update_melee_hitbox_position() -> void:
	if melee_hitbox:
		melee_hitbox.position = Vector2(melee_offset.x * facing_direction, melee_offset.y)


func _on_melee_hitbox_body_entered(body: Node2D) -> void:
	if not is_attacking:
		return

	if body.has_method("take_damage"):
		body.take_damage(1)
