extends CollisionShape2D

var collectables = 0
func on_body_entered() -> void:
	collectables = collectables + 1
	
	pass
