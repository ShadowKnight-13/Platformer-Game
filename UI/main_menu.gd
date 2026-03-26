extends CanvasLayer

var text_size
@onready var anim = $SceneFade/Fade

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxBottom/StartButton.grab_focus()
	text_size = UiGlobals.text_size
	set_font_size_recursive(self, text_size)
	fade_in()
	if has_node("/root/Music"):
		get_node("/root/Music").call("play", "title", 1.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	var tree := get_tree()
	tree.change_scene_to_file("res://Main.tscn")
	await tree.process_frame
	var main := tree.get_first_node_in_group("GameMain")
	if main and main.has_method("load_level"):
		main.call("load_level", "res://Levels/DesertCave.tscn")


func _on_settings_button_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://UI/settings_menu.tscn")


func _on_quit_button_pressed() -> void:
	#emit_signal("pressed")
	fade_out()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0)

func set_font_size_recursive(node: Node, size: int):
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		if child.name == "Title":
			return
		else:
			set_font_size_recursive(child, size)


func _on_level_select_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://UI/level_select.tscn")

func fade_in():
	$SceneFade.show()
	anim.play("fade_in")
	await get_tree().create_timer(1.0).timeout
	$SceneFade.hide()

func fade_out():
	$SceneFade.show()
	$SceneFade/AudioStreamPlayer2D.play()
	anim.play("fade_out")
