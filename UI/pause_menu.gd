extends VBoxContainer

var is_paused = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if is_paused == false:
			get_tree().paused = not get_tree().paused
			is_paused = true
			show()
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
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
