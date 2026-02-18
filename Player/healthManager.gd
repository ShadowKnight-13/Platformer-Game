extends HBoxContainer

# Preloads the textures to reduce any lag
var hearts_full = preload("res://Art Assets/hearts/heart_32x32.png")

# Checks for updates to health count and changes how many hearts are displayed
func update_health_ui(health: int):
	
	for i in get_child_count():
		var heart = get_child(i) as TextureRect
		
		if health > i:
			heart.texture = hearts_full
			heart.visible = true
			
		else:
			heart.visible = false

# Recieves signal emited from player node.
func _on_player_health_changed(health) -> void:
	update_health_ui(health)
