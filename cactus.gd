extends StaticBody2D

@export var damage_amount: = 1

# want this to damage player by when colliding

# maybe be able to damage catus object so it's destroyed


func _on_hurt_box_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body.is_in_group("player"):
		body.damage_player(-1)
		print("Ouch!")
