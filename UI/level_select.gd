extends CanvasLayer

var text_size

func _ready() -> void:
	text_size = UiGlobals.text_size
	set_font_size_recursive(self, text_size)

func _process(delta: float) -> void:
	pass

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")

func set_font_size_recursive(node: Node, size: int) -> void:
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		set_font_size_recursive(child, size)

