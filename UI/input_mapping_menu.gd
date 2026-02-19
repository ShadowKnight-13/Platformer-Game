extends CanvasLayer

var listening_for
var text_size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_size = UiGlobals.text_size
	set_font_size_recursive(self, text_size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_font_size_recursive(node: Node, size: int):
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		set_font_size_recursive(child, size)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/settings_menu.tscn")


func _input(event):
	if listening_for == "left" and event.pressed:
		# Update InputMap
		InputMap.action_erase_events("move_left")
		InputMap.action_add_event("move_left", event)

		# Update the UI text
		$HBoxContainer/VBoxKeyboard/LeftKey.text = event.as_text()

		# Stop listening
		listening_for = ""


func _on_left_key_pressed() -> void:
	pass
