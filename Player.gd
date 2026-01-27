extends CharacterBody2D


const SPEED = 300.0
const JUMP_HEIGHT: float = -500.0
const FRICTION: float = 22.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
const GRAVITY_NORMAL: float = 14.5
const GRAVITY_WALL: float = 100.5
const WALL_JUMP_PUSH_FORCE: float = 1000.0

var wall_contact_coyote: float = 0.0
const WALL_CONTACT_COYOTE_TIME: float = 0.2

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.05

var wall_stick_time := 0.0
const WALL_STICK_DURATION := 0.5

var look_dir_x: int = 1

var health = 3
var x_input: float = 0.0
var velocity_weight_x := 0.15

signal health_changed


	
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
	
	x_input = Input.get_axis("move_left", "move_right")
	# Add the gravity.
	#if not is_on_floor() and velocity.y > 0 and is_on_wall() and velocity.x !=0:
	if is_on_wall() and not is_on_floor():
		if wall_stick_time < WALL_STICK_DURATION:
			wall_stick_time += delta
			velocity.y = 0  # stick to wall
		else:
			velocity.y = GRAVITY_WALL  # start sliding
			look_dir_x = sign(velocity.x)
			wall_contact_coyote = WALL_CONTACT_COYOTE_TIME
	else:
		wall_stick_time = 0.0
		wall_contact_coyote -= delta
		velocity.y += GRAVITY_NORMAL
		#look_dir_x = sign(velocity.x)
		#wall_contact_coyote = WALL_CONTACT_COYOTE_TIME
		#velocity.y = GRAVITY_WALL
	#else:
		#wall_contact_coyote -= delta
		#velocity.y += GRAVITY_NORMAL

	if is_on_floor() or wall_contact_coyote> 0.0:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_HEIGHT
			if wall_contact_coyote >0.0:
				velocity.x = -look_dir_x * WALL_JUMP_PUSH_FORCE
				wall_jump_lock = WALL_JUMP_LOCK_TIME
	
	if wall_jump_lock > 0.0:
		wall_jump_lock -= delta
		velocity.x = lerp(velocity.x, x_input * SPEED,velocity_weight_x *0.5)
	else:
		velocity.x = lerp(velocity.x,x_input * SPEED, velocity_weight_x)

	print("on_wall: ", is_on_wall(), "   vel.x: ", velocity.x)
	
	#Jump/fall animation check
	if not is_on_floor():
		if velocity.y < 0:
			$AnimationPlayer.play("Jump")
		else:
			$AnimationPlayer.play("Fall")
		
		print(velocity.y)

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
		$AnimationPlayer.play("Run")
		if velocity.x < 0:
			$Sprite2D.flip_h = true
		elif velocity.x > 0:
			$Sprite2D.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	player_death()
	kill_player()
	damage_player()
	

	
