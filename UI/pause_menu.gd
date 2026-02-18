extends VBoxContainer

var is_paused = false
var text_size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	text_size = UiGlobals.text_size
	set_font_size_recursive(self, text_size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if is_paused == false:
			get_tree().paused = not get_tree().paused
			is_paused = true
			show()
			$ResumeButton.grab_focus()
		elif is_paused == true:
			get_tree().paused = not get_tree().paused
			is_paused = false
			hide()


func _on_resume_button_pressed() -> void:
	get_tree().paused = not get_tree().paused
	is_paused = false
	hide()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = not get_tree().paused
	is_paused = false
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")

func set_font_size_recursive(node: Node, size: int):
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		set_font_size_recursive(child, size)
