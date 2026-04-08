extends AnimatableBody2D

# Movement settings
@export_group("Movement")
@export var forward_speed: float = 100.0
@export var return_speed: float = 100.0
@export var move_mode: MoveMode = MoveMode.PING_PONG
@export var forward_wait_time: float = 1.0
@export var return_wait_time: float = 1.0
@export var inactive_speed: float = 0.0
@export var active_speed: float = 100.0
var _base_forward: float
var _base_return: float

# Simple path definition
@export_group("Path Points")
@export var path_points: Array[Vector2] = [Vector2(0, 0), Vector2(200, 0)]

# Platform size
@export_group("Platform Size")
@export var platform_size: Vector2 = Vector2(64, 16)

# Crush detection
@export_group("Crush Settings")
@export var can_crush: bool = true
@export var crush_distance: float = 20.0
@export var can_crush_up: bool = true
@export var can_crush_down: bool = true
@export var can_crush_right: bool = true
@export var can_crush_left: bool = true
@export var can_crush_enemies: bool = true

@export_group("puzzle")
@export var puzzle_controlled: bool = false

# Path following
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D
@onready var path_2d: Path2D = $Path2D

# Track the platform's starting position
var start_position: Vector2

# Internal state
var direction: int = 1
var waiting: bool = false
var wait_timer: float = 0.0

# Debug drawing
var debug_rays: Array = []

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
	_base_forward = forward_speed
	_base_return = return_speed
	if puzzle_controlled:
		forward_speed = inactive_speed
		return_speed = inactive_speed
	_apply_platform_size()

func _apply_platform_size() -> void:
	scale = Vector2.ONE
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is RectangleShape2D:
			if not collision_shape.shape.is_local_to_scene():
				collision_shape.shape = collision_shape.shape.duplicate()
			collision_shape.shape.size = platform_size
			collision_shape.scale = Vector2.ONE
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		if sprite.texture:
			var tex_size = sprite.texture.get_size()
			sprite.scale = platform_size / tex_size
	if has_node("ColorRect"):
		var rect = $ColorRect
		rect.size = platform_size
		rect.position = -platform_size / 2.0

func build_path() -> void:
	var curve = Curve2D.new()
	for point in path_points:
		curve.add_point(point)
	path_2d.curve = curve

func _get_current_speed() -> float:
	if direction == 1:
		return forward_speed
	else:
		return return_speed

const MAX_STEP_DISTANCE: float = 8.0

func _physics_process(delta: float) -> void:
	if waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			waiting = false
			direction *= -1
		return

	var current_speed = _get_current_speed()
	var speed_based_crush = crush_distance + (current_speed * delta)

	var total_movement = current_speed * delta
	var step_count = max(1, ceili(total_movement / MAX_STEP_DISTANCE))
	var sub_delta = delta / float(step_count)

	for i in range(step_count):
		match move_mode:
			MoveMode.LOOP:
				move_loop(sub_delta, current_speed)
			MoveMode.PING_PONG:
				if move_ping_pong(sub_delta, current_speed, speed_based_crush):
					break
			MoveMode.ONCE:
				move_once(sub_delta, current_speed)

		update_platform_position()

		if can_crush:
			check_for_crush(speed_based_crush)

func move_loop(delta: float, current_speed: float) -> void:
	path_follow.progress += current_speed * delta
	if path_follow.progress_ratio >= 1.0:
		path_follow.progress = 0.0

func move_ping_pong(delta: float, current_speed: float, effective_crush_distance: float) -> bool:
	path_follow.progress += current_speed * delta * direction
	if direction > 0 and path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		start_waiting(true)
		update_platform_position()
		if can_crush:
			check_for_crush(effective_crush_distance)
		return true
	elif direction < 0 and path_follow.progress_ratio <= 0.0:
		path_follow.progress_ratio = 0.0
		start_waiting(false)
		update_platform_position()
		if can_crush:
			check_for_crush(effective_crush_distance)
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


# === DEBUG HELPERS ===

func _get_debug_player() -> Node2D:
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
	debug_rays.append(data)

func _process(_delta: float) -> void:
	if _is_debug_visible():
		queue_redraw()
	else:
		if debug_rays.size() > 0:
			debug_rays.clear()
			queue_redraw()

func _draw() -> void:
	if not _is_debug_visible():
		return
	for ray in debug_rays:
		if ray.type == "line":
			draw_line(ray.start - global_position, ray.end - global_position, ray.color, 2.0)
		elif ray.type == "circle":
			draw_circle(ray.pos - global_position, 5, ray.color)
	debug_rays.clear()


# === CRUSH DETECTION (ALL 4 DIRECTIONS) ===

func _get_platform_edges() -> Dictionary:
	var collision_shape = $CollisionShape2D
	var shape = collision_shape.shape
	var half_w = 0.0
	var half_h = 0.0
	if shape is RectangleShape2D:
		half_w = shape.size.x / 2.0
		half_h = shape.size.y / 2.0
	elif shape is CapsuleShape2D:
		half_w = shape.radius
		half_h = shape.height / 2.0
	var root_scale = global_transform.get_scale()
	var total_scale_x = collision_shape.scale.x * root_scale.x
	var total_scale_y = collision_shape.scale.y * root_scale.y
	half_w *= abs(total_scale_x)
	half_h *= abs(total_scale_y)
	var shape_offset = collision_shape.position * root_scale
	var center = global_position + shape_offset
	return {
		"center": center,
		"half_w": half_w,
		"half_h": half_h,
		"left": center.x - half_w,
		"right": center.x + half_w,
		"top": center.y - half_h,
		"bottom": center.y + half_h,
	}


func check_for_crush(effective_crush_distance: float = -1.0) -> void:
	var space_state = get_world_2d().direct_space_state
	var show_debug = _is_debug_visible()

	var collision_shape = $CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return

	var cd = effective_crush_distance if effective_crush_distance > 0 else crush_distance
	var edges = _get_platform_edges()

	var x_positions: Array[float] = _build_ray_positions(edges.left, edges.right, 10.0)
	var y_positions: Array[float] = _build_ray_positions(edges.top, edges.bottom, 10.0)

	# === UP CHECK ===
	if can_crush_up:
		for ray_x in x_positions:
			var ray_start = Vector2(ray_x, edges.top + 4.0)
			var ray_end = Vector2(ray_x, edges.top - cd)
			_crush_check_direction(space_state, ray_start, ray_end, Vector2.UP, show_debug, cd)

	# === DOWN CHECK ===
	if can_crush_down:
		for ray_x in x_positions:
			var ray_start = Vector2(ray_x, edges.bottom - 4.0)
			var ray_end = Vector2(ray_x, edges.bottom + cd)
			_crush_check_direction(space_state, ray_start, ray_end, Vector2.DOWN, show_debug, cd)

	# === LEFT CHECK ===
	if can_crush_left:
		for ray_y in y_positions:
			var ray_start = Vector2(edges.left + 4.0, ray_y)
			var ray_end = Vector2(edges.left - cd, ray_y)
			_crush_check_direction(space_state, ray_start, ray_end, Vector2.LEFT, show_debug, cd)

	# === RIGHT CHECK ===
	if can_crush_right:
		for ray_y in y_positions:
			var ray_start = Vector2(edges.right - 4.0, ray_y)
			var ray_end = Vector2(edges.right + cd, ray_y)
			_crush_check_direction(space_state, ray_start, ray_end, Vector2.RIGHT, show_debug, cd)


## Unified crush check that handles both players and enemies in one raycast
func _crush_check_direction(space_state: PhysicsDirectSpaceState2D, ray_start: Vector2, ray_end: Vector2, crush_direction: Vector2, show_debug: bool, cd: float) -> void:
	# Cast on both player (layer 1) and enemy (layer 4, bit value 8) layers
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [self]
	query.collision_mask = 1 | 8  # Player (1) + Enemy layer 4 (8)
	var result = space_state.intersect_ray(query)

	if show_debug:
		var hit = result.size() > 0
		var color = Color.YELLOW if hit else Color.MAGENTA
		_add_debug_ray({"type": "line", "start": ray_start, "end": result.position if hit else ray_end, "color": color})
		if hit:
			_add_debug_ray({"type": "circle", "pos": result.position, "color": color})

	if not result:
		return

	var collider = result.collider

	# --- Player crush (existing behavior) ---
	if collider.is_in_group("player"):
		if is_player_crushed(collider, crush_direction, show_debug):
			if collider.has_method("kill_player"):
				collider.kill_player()
				print("Player crushed by platform!")

	# --- Enemy crush (new) ---
	elif can_crush_enemies and collider is BaseEnemy:
		if _is_enemy_crushed(collider, crush_direction, cd):
			collider.take_damage(collider.health)  # Instant kill
			print("Enemy crushed by platform!")


func _is_enemy_crushed(enemy: BaseEnemy, crush_direction: Vector2, cd: float) -> bool:
	var space_state = get_world_2d().direct_space_state
	var edges = _get_platform_edges()

	# Get enemy collision size
	var enemy_collision = enemy.get_node_or_null("CollisionShape2D")
	if not enemy_collision or not enemy_collision.shape:
		return false

	var enemy_width = 0.0
	var enemy_height = 0.0
	if enemy_collision.shape is RectangleShape2D:
		enemy_width = enemy_collision.shape.size.x * enemy_collision.scale.x
		enemy_height = enemy_collision.shape.size.y * enemy_collision.scale.y
	elif enemy_collision.shape is CapsuleShape2D:
		var capsule = enemy_collision.shape as CapsuleShape2D
		enemy_width = capsule.radius * 2.0 * enemy_collision.scale.x
		enemy_height = capsule.height * enemy_collision.scale.y

	# Cast from platform edge through the enemy to find a wall behind them
	var ray_start = Vector2.ZERO
	var check_distance = 0.0

	if crush_direction == Vector2.UP:
		ray_start = Vector2(enemy.global_position.x, edges.top - 1.0)
		check_distance = enemy_height + cd
	elif crush_direction == Vector2.DOWN:
		ray_start = Vector2(enemy.global_position.x, edges.bottom + 1.0)
		check_distance = enemy_height + cd
	elif crush_direction == Vector2.LEFT:
		ray_start = Vector2(edges.left - 1.0, enemy.global_position.y)
		check_distance = enemy_width + cd
	elif crush_direction == Vector2.RIGHT:
		ray_start = Vector2(edges.right + 1.0, enemy.global_position.y)
		check_distance = enemy_width + cd

	var ray_end = ray_start + (crush_direction * check_distance)

	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [enemy, self]
	query.collision_mask = 2  # World layer only

	var result = space_state.intersect_ray(query)

	if result:
		var space_available = 0.0
		if crush_direction == Vector2.UP:
			space_available = abs(edges.top - result.position.y)
		elif crush_direction == Vector2.DOWN:
			space_available = abs(result.position.y - edges.bottom)
		elif crush_direction == Vector2.LEFT:
			space_available = abs(edges.left - result.position.x)
		elif crush_direction == Vector2.RIGHT:
			space_available = abs(result.position.x - edges.right)

		var required_space = 0.0
		if crush_direction == Vector2.UP or crush_direction == Vector2.DOWN:
			required_space = enemy_height
		else:
			required_space = enemy_width

		return space_available < required_space

	return false


func _build_ray_positions(edge_min: float, edge_max: float, spacing: float) -> Array[float]:
	var positions: Array[float] = []
	positions.append(edge_min)
	var total_length = edge_max - edge_min
	if total_length > 0:
		var fill_count = int(total_length / spacing)
		if fill_count > 0:
			var actual_spacing = total_length / float(fill_count + 1)
			for i in range(1, fill_count + 1):
				positions.append(edge_min + actual_spacing * float(i))
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
	var edges = _get_platform_edges()
	var ray_start = Vector2.ZERO
	var check_distance = 0.0
	if crush_direction == Vector2.UP:
		ray_start = Vector2(player.global_position.x, edges.top - 1.0)
		check_distance = player_height + crush_distance
	elif crush_direction == Vector2.DOWN:
		ray_start = Vector2(player.global_position.x, edges.bottom + 1.0)
		check_distance = player_height + crush_distance
	elif crush_direction == Vector2.LEFT:
		ray_start = Vector2(edges.left - 1.0, player.global_position.y)
		check_distance = player_width + crush_distance
	elif crush_direction == Vector2.RIGHT:
		ray_start = Vector2(edges.right + 1.0, player.global_position.y)
		check_distance = player_width + crush_distance
	var ray_end = ray_start + (crush_direction * check_distance)
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [player, self]
	query.collision_mask = 2
	var result = space_state.intersect_ray(query)
	if show_debug:
		var hit = result.size() > 0
		var color = Color.RED if hit else Color.CYAN
		_add_debug_ray({"type": "line", "start": ray_start, "end": result.position if hit else ray_end, "color": color})
		if hit:
			_add_debug_ray({"type": "circle", "pos": result.position, "color": Color.RED})
	if result:
		var space_available = 0.0
		if crush_direction == Vector2.UP:
			space_available = abs(edges.top - result.position.y)
		elif crush_direction == Vector2.DOWN:
			space_available = abs(result.position.y - edges.bottom)
		elif crush_direction == Vector2.LEFT:
			space_available = abs(edges.left - result.position.x)
		elif crush_direction == Vector2.RIGHT:
			space_available = abs(result.position.x - edges.right)
		var required_space = 0.0
		if crush_direction == Vector2.UP or crush_direction == Vector2.DOWN:
			required_space = player_height
		else:
			required_space = player_width
		return space_available < required_space
	return false


func _cast_for_player(space_state: PhysicsDirectSpaceState2D, ray_start: Vector2, ray_end: Vector2, show_debug: bool, debug_color: Color) -> Node2D:
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.exclude = [self]
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	if show_debug:
		var hit = result.size() > 0
		var color = Color.YELLOW if (hit and result.collider.is_in_group("player")) else debug_color
		_add_debug_ray({"type": "line", "start": ray_start, "end": result.position if hit else ray_end, "color": color})
		if hit:
			_add_debug_ray({"type": "circle", "pos": result.position, "color": color})
	if result and result.collider.is_in_group("player"):
		return result.collider
	return null

func set_platform_active(active: bool) -> void:
	if not puzzle_controlled:
		return
	var s: float = active_speed if active else inactive_speed
	forward_speed = s
	return_speed = s
