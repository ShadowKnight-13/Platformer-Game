extends BaseEnemy

@export var idle_speed: float = 0.0
@export var charge_speed: float = 300.0
@export var follow_speed: float = 300.0
@export var acceleration: float = 10.0
@export var sight_range: float = 300.0
@export var charge_duration: float = 1.0

enum State { IDLE, CHARGE, FOLLOW }

var state: State = State.IDLE
var _charge_timer: float = 0.0
var gravity: float = 900.0

@onready var player: CharacterBody2D = null

func _ready() -> void:
	super._ready() # Initialize health from BaseEnemy 
	# Finds player in the "player" group [cite: 2, 4, 38]
	player = get_tree().get_first_node_in_group("player") 

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	
	match state:
		State.IDLE:
			$AnimationPlayer.play("Idle")
			_idle_update(delta)
		State.CHARGE:
			$AnimationPlayer.play("Run") # Or a "Charge" animation if you have one
			_charge_update(delta)
		State.FOLLOW:
			$AnimationPlayer.play("Run")
			_follow_update(delta)

	move_and_slide()
	
	# Handle sprite flipping based on movement direction
	if velocity.x < 0:
		$Sprite2D.flip_h = false
	elif velocity.x > 0:
		$Sprite2D.flip_h = true

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _idle_update(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, acceleration)
	
	# Check for player detection
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player <= sight_range:
		_enter_charge_state()

func _enter_charge_state() -> void:
	state = State.CHARGE
	_charge_timer = charge_duration
	if has_node("ChargeSound"): # Optional sound trigger like your example's $dive.play()
		$ChargeSound.play()

func _charge_update(delta: float) -> void:
	_charge_timer -= delta
	
	if player != null:
		var dir = sign(player.global_position.x - global_position.x)
		velocity.x = move_toward(velocity.x, dir * charge_speed, acceleration * 2)
	
	if _charge_timer <= 0:
		state = State.FOLLOW

func _follow_update(_delta: float) -> void:
	if player != null:
		var dir = sign(player.global_position.x - global_position.x)
		velocity.x = move_toward(velocity.x, dir * follow_speed, acceleration)

func _on_detection_area_body_entered(body: Node2D) -> void:
	# Optional helper: acquire target when player enters detection radius.
	if body != null and body.is_in_group("player"):
		player = body as CharacterBody2D

# Use your existing damage logic from the BaseEnemy/Player interaction
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("damage_player"):
		body.damage_player() # Calls the player's damage function
