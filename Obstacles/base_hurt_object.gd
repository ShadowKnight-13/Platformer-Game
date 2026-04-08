extends StaticBody2D
class_name BaseHurtObject

@export var damage_amount: int = 1
@export var affects_enemies: bool = true
@export var hurt_cooldown: float = 0.5

var _hurt_timers: Dictionary = {}

func _ready() -> void:
	var hurt_box = get_node_or_null("HurtBox")
	if hurt_box and hurt_box is Area2D:
		# Enemies are on collision_layer = 8, which is layer 4 (bit index 3)
		hurt_box.collision_mask |= (1 << 3)  # Enable layer 4 (bit value 8)

func _physics_process(delta: float) -> void:
	# Tick down cooldown timers
	for body_id in _hurt_timers.keys():
		_hurt_timers[body_id] -= delta
		if _hurt_timers[body_id] <= 0.0:
			_hurt_timers.erase(body_id)

	if not affects_enemies:
		return

	var hurt_box = get_node_or_null("HurtBox")
	if hurt_box == null or not hurt_box is Area2D:
		return

	for body in hurt_box.get_overlapping_bodies():
		if body is BaseEnemy and not _hurt_timers.has(body.get_instance_id()):
			body.take_damage(damage_amount)
			_hurt_timers[body.get_instance_id()] = hurt_cooldown

func _on_hurt_box_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body.is_in_group("player"):
		if body.has_method("kill_player") and damage_amount >= 9999:
			body.kill_player()
		elif body.has_method("damage_player"):
			body.damage_player()
		return

	if affects_enemies and body is BaseEnemy:
		if not _hurt_timers.has(body.get_instance_id()):
			body.take_damage(damage_amount)
			_hurt_timers[body.get_instance_id()] = hurt_cooldown
