extends Area2D

func _on_KillBox_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body.is_in_group("player"):
		body.Kill_player()
		print("Death!")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.kill_player()
		print("Death!")
