extends Area2D

#needs code to play idle wave anim before & after collection

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	CheckpointManager.set_checkpoint(global_position, body.health)
	set("monitoring", false)
	$AnimationPlayer.play("Get")
