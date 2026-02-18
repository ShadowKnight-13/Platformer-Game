extends CanvasLayer

var is_fullscreen = false
var text_size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer/VBoxCenterRight/ResolutionDropDown.grab_focus()
	text_size = UiGlobals.text_size
	$HBoxContainer/VBoxCenterRight/TextSizeDropDown.selected = UiGlobals.text_size_slected
	$HBoxContainer/VBoxCenterRight/ResolutionDropDown.selected = UiGlobals.resolution_slected
	$HBoxContainer/VBoxCenterRight/FullscreenToggle.button_pressed = UiGlobals.is_fullscreen
	set_font_size_recursive(self, UiGlobals.text_size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")


func _on_resolution_drop_down_item_selected(index: int) -> void:
	if index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		if is_fullscreen == true:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		UiGlobals.resolution = Vector2i(1280, 720)
		UiGlobals.resolution_slected = 0
	elif index == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1600, 900))
		if is_fullscreen == true:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		UiGlobals.resolution = Vector2i(1600, 900)
		UiGlobals.resolution_slected = 1
	elif index == 2:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		if is_fullscreen == true:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		UiGlobals.resolution = Vector2i(1920, 1080)
		UiGlobals.resolution_slected = 2
	elif index == 3:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(2560, 1440))
		if is_fullscreen == true:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		UiGlobals.resolution = Vector2i(2560, 1440)
		UiGlobals.resolution_slected = 3


func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		UiGlobals.is_fullscreen = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		UiGlobals.is_fullscreen = false


func _on_text_size_drop_down_item_selected(index: int) -> void:
	if index == 0:
		text_size = 18
		UiGlobals.text_size_slected = 0
	elif index == 1:
		text_size = 24
		UiGlobals.text_size_slected = 1
	elif index == 2:
		text_size = 32
		UiGlobals.text_size_slected = 2
	set_font_size_recursive(self, text_size)
	UiGlobals.text_size = text_size

func set_font_size_recursive(node: Node, size: int):
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		set_font_size_recursive(child, size)


func _on_input_mapping_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/input_mapping_menu.tscn")
