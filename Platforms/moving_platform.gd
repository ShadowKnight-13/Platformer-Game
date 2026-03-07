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
@export var crush_distance: float = 20.0  # How far from platform edge to check for player

# Path following
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D
@onready var path_2d: Path2D = $Path2D

# Track the platform's starting position
var start_position: Vector2

# Internal state
var direction: int = 1
var waiting: bool = false
var wait_timer: float = 0.0

# Debug drawing — platform stores its own rays each frame
var debug_rays: Array = []

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


# === DEBUG HELPERS ===

func _get_debug_player() -> Node2D:
	## Find the player node so we can read debug_rays_visible
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _is_debug_visible() -> bool:
	var player = _get_debug_player()
	if player and "debug_rays_visible" in player:
		return player.debug_rays_visible
	return false

func _add_debug_ray(data: Dictionary) -> void:
	## Push a ray dict into the platform's own debug_rays array
	debug_rays.append(data)

func _process(_delta: float) -> void:
	# Only redraw when debug is on
	if _is_debug_visible():
		queue_redraw()
	else:
		# Clear leftover data when debug is toggled off
		if debug_rays.size() > 0:
			debug_rays.clear()
			queue_redraw()

func _draw() -> void:
	if not _is_debug_visible():
		return
	
	for ray in debug_rays:
		if ray.type == "line":
			# Convert from global to local coords (same pattern as Player._draw)
			draw_line(ray.start - global_position, ray.end - global_position, ray.color, 2.0)
		elif ray.type == "circle":
			draw_circle(ray.pos - global_position, 5, ray.color)
	
	# Clear AFTER drawing, ready for next physics frame
	debug_rays.clear()


# === CRUSH DETECTION (ALL 4 DIRECTIONS) ===
func check_for_crush() -> void:
	var space_state = get_world_2d().direct_space_state
	var show_debug = _is_debug_visible()
	
	# Get platform collision shape to determine size
	var collision_shape = $CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return
	
	var shape = collision_shape.shape
	var platform_half_width = 0.0
	var platform_half_height = 0.0
	
	if shape is RectangleShape2D:
		platform_half_width = (shape.size.x * collision_shape.scale.x) / 2.0
		platform_half_height = (shape.size.y * collision_shape.scale.y) / 2.0
	elif shape is CapsuleShape2D:
		platform_half_width = shape.radius * collision_shape.scale.x
		platform_half_height = (shape.height / 2.0) * collision_shape.scale.y
	
	# The TRUE center of the collision shape in world space
	var shape_center = global_position + collision_shape.position
	
	# The exact four edges
	var left_edge = shape_center.x - platform_half_width
	var right_edge = shape_center.x + platform_half_width
	var top_edge = shape_center.y - platform_half_height
	var bottom_edge = shape_center.y + platform_half_height
	
	# Build X positions: corners first, then evenly spaced fill between
	var x_positions: Array[float] = _build_ray_positions(left_edge, right_edge, 10.0)
	# Build Y positions: corners first, then evenly spaced fill between
	var y_positions: Array[float] = _build_ray_positions(top_edge, bottom_edge, 10.0)
	
	# === UP CHECK (platform pushing player into ceiling) ===
	for ray_x in x_positions:
		var ray_start = Vector2(ray_x, top_edge - 1.0)
		var ray_end = Vector2(ray_x, top_edge - 1.0 - crush_distance)
		
		var player = _cast_for_player(space_state, ray_start, ray_end, show_debug, Color.MAGENTA)
		if player and is_player_crushed(player, Vector2.UP, show_debug):
			if player.has_method("kill_player"):
				player.kill_player()
				print("Player crushed by platform (from below)!")
			return
	
	# === DOWN CHECK (platform pushing player into floor) ===
	for ray_x in x_positions:
		var ray_start = Vector2(ray_x, bottom_edge + 1.0)
		var ray_end = Vector2(ray_x, bottom_edge + 1.0 + crush_distance)
		
		var player = _cast_for_player(space_state, ray_start, ray_end, show_debug, Color.MAGENTA)
		if player and is_player_crushed(player, Vector2.DOWN, show_debug):
			if player.has_method("kill_player"):
				player.kill_player()
				print("Player crushed by platform (from above)!")
			return
	
	# === LEFT CHECK (platform pushing player into right wall) ===
	for ray_y in y_positions:
		var ray_start = Vector2(left_edge - 1.0, ray_y)
		var ray_end = Vector2(left_edge - 1.0 - crush_distance, ray_y)
		
		var player = _cast_for_player(space_state, ray_start, ray_end, show_debug, Color.MAGENTA)
		if player and is_player_crushed(player, Vector2.LEFT, show_debug):
			if player.has_method("kill_player"):
				player.kill_player()
				print("Player crushed by platform (from right)!")
			return
	
	# === RIGHT CHECK (platform pushing player into left wall) ===
	for ray_y in y_positions:
		var ray_start = Vector2(right_edge + 1.0, ray_y)
		var ray_end = Vector2(right_edge + 1.0 + crush_distance, ray_y)
		
		var player = _cast_for_player(space_state, ray_start, ray_end, show_debug, Color.MAGENTA)
		if player and is_player_crushed(player, Vector2.RIGHT, show_debug):
			if player.has_method("kill_player"):
				player.kill_player()
				print("Player crushed by platform (from left)!")
			return


func _build_ray_positions(edge_min: float, edge_max: float, spacing: float) -> Array[float]:
	## Always includes both corners (edge_min and edge_max).
	## Fills evenly spaced rays between them based on spacing.
	var positions: Array[float] = []
	
	# Always add the first corner
	positions.append(edge_min)
	
	# Calculate how many fill rays we need between the corners
	var total_length = edge_max - edge_min
	if total_length > 0:
		var fill_count = int(total_length / spacing)
		if fill_count > 0:
			var actual_spacing = total_length / float(fill_count + 1)
			for i in range(1, fill_count + 1):
				positions.append(edge_min + actual_spacing * float(i))
	
	# Always add the second corner
	positions.append(edge_max)
	
	return positions


func is_player_crushed(player: Node2D, crush_direction: Vector2, show_debug: bool) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	var player_collision = player.get_node_or_null("CollisionShape2D")
	if not player_collision or not player_collision.shape:
		return false
	
	var player_width = 0.0
	var player_height = 0.0
	if player_collision.shape is RectangleShape2D:
		player_width = player_collision.shape.size.x * player_collision.scale.x
		player_height = player_collision.shape.size.y * player_collision.scale.y
	
	var check_distance = 0.0
	if crush_direction == Vector2.UP or crush_direction == Vector2.DOWN:
		check_distance = player_height + 5.0
	else:
		check_distance = player_width + 5.0
	
	var ray_start = player.global_position
	var ray_end = ray_start + (crush_direction * check_distance)
	
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [player, self]
	query.collision_mask = 2  # World layer
	
	var result = space_state.intersect_ray(query)
	
	if show_debug:
		var hit = result.size() > 0
		var color = Color.RED if hit else Color.CYAN
		_add_debug_ray({
			"type": "line",
			"start": ray_start,
			"end": result.position if hit else ray_end,
			"color": color
		})
		if hit:
			_add_debug_ray({"type": "circle", "pos": result.position, "color": Color.RED})
	
	if result:
		var collision_shape = $CollisionShape2D
		var shape_center = global_position + collision_shape.position
		var shape = collision_shape.shape
		var phw = 0.0
		var phh = 0.0
		if shape is RectangleShape2D:
			phw = (shape.size.x * collision_shape.scale.x) / 2.0
			phh = (shape.size.y * collision_shape.scale.y) / 2.0
		
		var space_available = 0.0
		if crush_direction == Vector2.UP:
			space_available = abs((shape_center.y - phh) - result.position.y)
		elif crush_direction == Vector2.DOWN:
			space_available = abs(result.position.y - (shape_center.y + phh))
		elif crush_direction == Vector2.LEFT:
			space_available = abs((shape_center.x - phw) - result.position.x)
		elif crush_direction == Vector2.RIGHT:
			space_available = abs(result.position.x - (shape_center.x + phw))
		
		var required_space = 0.0
		if crush_direction == Vector2.UP or crush_direction == Vector2.DOWN:
			required_space = player_height
		else:
			required_space = player_width
		
		return space_available < required_space
	
	return false


func _cast_for_player(space_state: PhysicsDirectSpaceState2D, ray_start: Vector2, ray_end: Vector2, show_debug: bool, debug_color: Color) -> Node2D:
	## Cast a ray on the player layer. Returns the player node if hit, null otherwise.
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [self]
	query.collision_mask = 1  # Player layer
	
	var result = space_state.intersect_ray(query)
	
	if show_debug:
		var hit = result.size() > 0
		# Magenta = searching for player, Yellow = found player
		var color = Color.YELLOW if (hit and result.collider.is_in_group("player")) else debug_color
		_add_debug_ray({
			"type": "line",
			"start": ray_start,
			"end": result.position if hit else ray_end,
			"color": color
		})
		if hit:
			_add_debug_ray({"type": "circle", "pos": result.position, "color": color})
	
	if result and result.collider.is_in_group("player"):
		return result.collider
	return null
