extends AnimatableBody2D

# Movement settings
@export_group("Movement")
@export var forward_speed: float = 100.0   # Speed when moving toward end point
@export var return_speed: float = 100.0    # Speed when moving back to start
@export var move_mode: MoveMode = MoveMode.PING_PONG
@export var forward_wait_time: float = 1.0  # Wait time when reaching the end point
@export var return_wait_time: float = 1.0   # Wait time when returning to the start point

# Simple path definition - edit these in inspector!
@export_group("Path Points")
@export var path_points: Array[Vector2] = [Vector2(0, 0), Vector2(200, 0)]

# Platform size — use THIS instead of scaling the root node transform
@export_group("Platform Size")
@export var platform_size: Vector2 = Vector2(64, 16)

# Crush detection
@export_group("Crush Settings")
@export var can_crush: bool = true

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
	start_position = global_position
	build_path()
	path_2d.position = Vector2.ZERO
	path_follow.progress = 0.0
	path_follow.rotates = false
	path_follow.loop = false
	
	# Apply the exported size to the collision shape (and sprite if you have one)
	_apply_platform_size()

func _apply_platform_size() -> void:
	# Reset root transform to identity — never scale the AnimatableBody2D itself
	scale = Vector2.ONE
	
	# Resize the collision shape directly
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is RectangleShape2D:
			# Use .duplicate() so instances don't share the same shape resource
			if not collision_shape.shape.is_local_to_scene():
				collision_shape.shape = collision_shape.shape.duplicate()
			collision_shape.shape.size = platform_size
			collision_shape.scale = Vector2.ONE  # No extra scale on the shape node either
	
	# If you have a Sprite2D or ColorRect, resize it to match
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		# Assuming the sprite texture is some base size, scale it to match platform_size
		if sprite.texture:
			var tex_size = sprite.texture.get_size()
			sprite.scale = platform_size / tex_size
	
	if has_node("ColorRect"):
		var rect = $ColorRect
		rect.size = platform_size
		rect.position = -platform_size / 2.0  # Center it

func build_path() -> void:
	var curve = Curve2D.new()
	for point in path_points:
		curve.add_point(point)
	path_2d.curve = curve

func _get_current_speed() -> float:
	# direction = 1 means moving forward (toward end), -1 means returning (toward start)
	if direction == 1:
		return forward_speed
	else:
		return return_speed

# Maximum distance the platform should move per substep (in pixels).
# If the platform would move further than this in one frame, we split it into multiple steps.
const MAX_STEP_DISTANCE: float = 8.0

func _physics_process(delta: float) -> void:
	if waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			waiting = false
			direction *= -1
		return

	var current_speed = _get_current_speed()

	var total_movement = current_speed * delta
	var step_count = max(1, ceili(total_movement / MAX_STEP_DISTANCE))
	var sub_delta = delta / float(step_count)

	for i in range(step_count):
		match move_mode:
			MoveMode.LOOP:
				move_loop(sub_delta, current_speed)
			MoveMode.PING_PONG:
				if move_ping_pong(sub_delta, current_speed):
					break
			MoveMode.ONCE:
				move_once(sub_delta, current_speed)

		update_platform_position()

func move_loop(delta: float, current_speed: float) -> void:
	path_follow.progress += current_speed * delta
	if path_follow.progress_ratio >= 1.0:
		path_follow.progress = 0.0

func move_ping_pong(delta: float, current_speed: float) -> bool:
	path_follow.progress += current_speed * delta * direction
	
	if direction > 0 and path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		start_waiting(true)
		update_platform_position()
		return true
	elif direction < 0 and path_follow.progress_ratio <= 0.0:
		path_follow.progress_ratio = 0.0
		start_waiting(false)
		update_platform_position()
		return true
	
	return false

func move_once(delta: float, current_speed: float) -> void:
	path_follow.progress += current_speed * delta
	if path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		set_physics_process(false)

func start_waiting(reached_end: bool) -> void:
	var wait = forward_wait_time if reached_end else return_wait_time
	if wait > 0:
		waiting = true
		wait_timer = wait
	else:
		direction *= -1

func update_platform_position() -> void:
	global_position = start_position + path_follow.position

