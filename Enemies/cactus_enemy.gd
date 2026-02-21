extends CharacterBody2D

@export var speed: float = 60.0
@export var gravity: float = 1200.0
@export var start_direction: int = -1

var dir: int = -1

@onready var ground_ahead: RayCast2D = $GroundAhead
@onready var wall_check: RayCast2D = $WallCheck
@onready var sprite: Node = get_node_or_null("Sprite2D")

func _ready() -> void:
	dir = start_direction
	flip_raycasts()
	$Area2D.body_entered.connect(_on_hurt_box_body_entered)
	# Exclude self so raycasts don't hit our own collision shape
	ground_ahead.add_exception_rid(get_rid())
	wall_check.add_exception_rid(get_rid())

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.x = dir * speed

	ground_ahead.force_raycast_update()
	wall_check.force_raycast_update()
	var hit_wall := is_on_wall()
	var no_floor_ahead := ground_ahead != null and not ground_ahead.is_colliding()
	var wall_ray_hit := wall_check != null and wall_check.is_colliding()

	var stepped_off_ledge := not is_on_floor() and no_floor_ahead and velocity.y >= 0
	if hit_wall or wall_ray_hit or (is_on_floor() and no_floor_ahead) or stepped_off_ledge:
		dir *= -1
		velocity.x = dir * speed
		flip_raycasts()
		if sprite is Sprite2D:
			(sprite as Sprite2D).flip_h = (dir > 0)

	move_and_slide()

func flip_raycasts() -> void:
	# Ray on the side we're moving: dir=-1 -> left (x=-20), dir=1 -> right (x=20)
	if ground_ahead:
		ground_ahead.position = Vector2(dir * 20, 14)
	if wall_check:
		wall_check.position = Vector2(dir * 20, 0)
		wall_check.target_position = Vector2(dir * 24, 0)

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.damage_player()
