extends AnimatableBody2D

# Movement settings
@export_group("Movement")
@export var speed: float = 100.0
@export var move_mode: MoveMode = MoveMode.PING_PONG
@export var wait_time: float = 1.0

# Simple path definition - edit these in inspector!
@export_group("Path Points")
@export var path_points: Array[Vector2] = [Vector2(0, 0), Vector2(200, 0)]

# Crush detection
@export_group("Crush Settings")
@export var can_crush: bool = true
@export var crush_distance: float = 20.0  # How far above platform to check for crushing

# Path following
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D
@onready var path_2d: Path2D = $Path2D

# Track the platform's starting position
var start_position: Vector2

# Internal state
var direction: int = 1
var waiting: bool = false
var wait_timer: float = 0.0

enum MoveMode {
	LOOP,
	PING_PONG,
	ONCE
}

func _ready() -> void:
	# Store initial position
	start_position = global_position
	
	# Build path from the points array
	build_path()
	
	# Ensure Path2D is at origin
	path_2d.position = Vector2.ZERO
	
	# Initialize PathFollow2D
	path_follow.progress = 0.0
	path_follow.rotates = false
	path_follow.loop = false

func build_path() -> void:
	# Create curve from path_points array
	var curve = Curve2D.new()
	
	for point in path_points:
		curve.add_point(point)
	
	path_2d.curve = curve

func _physics_process(delta: float) -> void:
	if waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			waiting = false
			direction *= -1
		return
	
	match move_mode:
		MoveMode.LOOP:
			move_loop(delta)
		MoveMode.PING_PONG:
			move_ping_pong(delta)
		MoveMode.ONCE:
			move_once(delta)
	
	update_platform_position()
	
	# Check for crush after moving
	if can_crush:
		check_for_crush()

func move_loop(delta: float) -> void:
	path_follow.progress += speed * delta
	
	if path_follow.progress_ratio >= 1.0:
		path_follow.progress = 0.0

func move_ping_pong(delta: float) -> void:
	path_follow.progress += speed * delta * direction
	
	if direction > 0 and path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		start_waiting()
	elif direction < 0 and path_follow.progress_ratio <= 0.0:
		path_follow.progress_ratio = 0.0
		start_waiting()

func move_once(delta: float) -> void:
	path_follow.progress += speed * delta
	
	if path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		set_physics_process(false)

func start_waiting() -> void:
	if wait_time > 0:
		waiting = true
		wait_timer = wait_time

func update_platform_position() -> void:
	global_position = start_position + path_follow.position

func check_for_crush() -> void:
	# Cast a ray upward from the platform to detect if player is being crushed
	var space_state = get_world_2d().direct_space_state
	
	# Get platform collision shape to determine width
	var collision_shape = $CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return
	
	var shape = collision_shape.shape
	var platform_width = 0.0
	
	# Get platform width based on shape type
	if shape is RectangleShape2D:
		platform_width = shape.size.x
	elif shape is CapsuleShape2D:
		platform_width = shape.radius * 2
	
	# Cast multiple rays across the platform width to detect player
	var num_rays = 5
	var start_x = global_position.x - platform_width / 2
	var end_x = global_position.x + platform_width / 2
	var step = platform_width / (num_rays - 1) if num_rays > 1 else 0
	
	for i in range(num_rays):
		var ray_x = start_x + (i * step)
		var ray_start = Vector2(ray_x, global_position.y - 5)  # Start slightly below platform top
		var ray_end = Vector2(ray_x, global_position.y - crush_distance)
		
		var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
		query.exclude = [self]
		query.collision_mask = 1  # Player layer
		
		var result = space_state.intersect_ray(query)
		
		if result:
			var collider = result.collider
			# Check if we hit the player
			if collider.is_in_group("player"):
				# Check if there's a ceiling above the player
				if is_player_crushed(collider):
					# Call the kill_player function
					if collider.has_method("kill_player"):
						collider.kill_player()
						print("Player crushed by platform!")
					break

func is_player_crushed(player: Node2D) -> bool:
	# Check if there's a solid object (ceiling/wall) above the player
	var space_state = get_world_2d().direct_space_state
	
	# Get player's collision shape height
	var player_collision = player.get_node_or_null("CollisionShape2D")
	if not player_collision or not player_collision.shape:
		return false
	
	var player_height = 0.0
	if player_collision.shape is RectangleShape2D:
		player_height = player_collision.shape.size.y * player_collision.scale.y
	
	# Cast ray upward from player to check for ceiling
	var ray_start = player.global_position
	var ray_end = player.global_position + Vector2(0, -player_height - 10)
	
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [player, self]
	query.collision_mask = 2  # World layer (ceilings, walls, etc.)
	
	var result = space_state.intersect_ray(query)
	
	# If we hit something above the player, they're being crushed
	if result:
		# Calculate the space between platform and ceiling
		var space_available = result.position.y - global_position.y
		# If space is less than player height, they're crushed
		return space_available < player_height
	
	return false
