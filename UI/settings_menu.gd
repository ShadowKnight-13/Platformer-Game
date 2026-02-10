extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/BackButton.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
