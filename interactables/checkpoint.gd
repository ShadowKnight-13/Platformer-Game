extends Area2D

#needs code to play idle wave anim before & after collection

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$AnimationPlayer.play("Wave1")

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	CheckpointManager.set_checkpoint(global_position, body.health)
	set_deferred("monitoring", false)
	$AnimationPlayer.play("Get")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Get":
		$AnimationPlayer.play("Wave2")
