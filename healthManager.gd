extends HBoxContainer

# Preloads the textures to reduce any lag
var hearts_full = preload("res://Assets/hearts/heart_32x32.png")

func update_health_ui(health: int):
	
	for i in get_child_count():
		var heart = get_child(i) as TextureRect
		
		if health > i:
			heart.texture = hearts_full
			heart.visible = true
			
		else:
			heart.visible = false

func _on_player_health_changed(health: Variant) -> void:
	update_health_ui(health)
	
