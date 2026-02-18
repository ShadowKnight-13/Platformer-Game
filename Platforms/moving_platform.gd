extends AnimatableBody2D

# Movement settings
@export_group("Movement")
@export var speed: float = 100.0
@export var move_mode: MoveMode = MoveMode.PING_PONG
@export var wait_time: float = 1.0

# Simple path definition - edit these in inspector!
@export_group("Path Points")
@export var path_points: Array[Vector2] = [Vector2(0, 0), Vector2(200, 0)]

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
