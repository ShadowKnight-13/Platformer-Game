extends BaseEnemy

@export var speed: float = 100.0
@export var charge_speed: float = 450.0
@export var acceleration: float = 15.0
@export var gravity: float = 900.0

var target_player: CharacterBody2D = null
var is_charging: bool = false
var has_detected: bool = false

func _ready() -> void:
	# Call the parent _ready to initialize health 
	super._ready()
	$AnimationPlayer.play("Idle")

func _physics_process(delta: float) -> void:
	# Apply basic gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if velocity.x > 0:
		$Sprite2d.flip_h = true
	if target_player:
		# Determine horizontal direction to player
		var direction = (target_player.global_position - global_position).normalized()
		
		# Choose speed based on whether we are currently "charging"
		var current_speed = charge_speed if is_charging else speed
		
		# Move toward the player horizontally
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration)
	else:
		# IDLE: Stand still until target_player is set
		velocity.x = move_toward(velocity.x, 0, acceleration)

	move_and_slide()

# This function will be linked to an Area2D signal in the editor
func _on_detection_area_body_entered(body: Node2D) -> void:
	# Ensure the body detected is actually the player
	print("body entered")
	if body.is_in_group("player"):
		target_player = body
		has_detected = true
		start_charge()
		$AnimationPlayer.play("Run")

func start_charge() -> void:
	is_charging = true
	print("Enemy Charging!")
	
	# After 0.8 seconds, slow down to normal follow speed
	await get_tree().create_timer(0.8).timeout
	is_charging = false
	print("Enemy now following at normal speed.")
