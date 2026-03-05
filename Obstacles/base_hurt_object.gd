extends StaticBody2D
class_name BaseHurtObject

@export var damage_amount: int = 1

func _on_hurt_box_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if not body.is_in_group("player"):
		return
	
	if body.has_method("kill_player") and damage_amount >= 9999:
		body.kill_player()
	else:
		if body.has_method("damage_player"):
			body.damage_player()

