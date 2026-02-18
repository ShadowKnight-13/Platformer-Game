extends CanvasLayer

var text_size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxBottom/StartButton.grab_focus()
	text_size = UiGlobals.text_size
	set_font_size_recursive(self, text_size)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/settings_menu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit(0)

func set_font_size_recursive(node: Node, size: int):
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		set_font_size_recursive(child, size)
