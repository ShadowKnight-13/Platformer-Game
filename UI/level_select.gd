extends CanvasLayer

var text_size
@onready var anim = $SceneFade/Fade

func _ready() -> void:
	$VBoxContainer/BackButton.grab_focus()
	#if UiGlobals.is_level2_unlocked == false:
		#$LevelButtons/Level2Button.disabled = true
	#if UiGlobals.is_level3_unlocked == false:
		#LevelButtons/Level3Button.disabled = true
	text_size = UiGlobals.text_size
	set_font_size_recursive(self, text_size)
	fade_in()
	if has_node("/root/Music"):
		get_node("/root/Music").call("play", "title", 1.0)

func _process(delta: float) -> void:
	pass

func _on_back_button_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")

func set_font_size_recursive(node: Node, size: int) -> void:
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		set_font_size_recursive(child, size)



func _on_level_1_button_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	var tree := get_tree()
	tree.change_scene_to_file("res://Main_DesertCave.tscn")


func _on_level_2_button_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	var tree := get_tree()
	tree.change_scene_to_file("res://Main_Desert.tscn")


func _on_level_3_button_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	var tree := get_tree()
	tree.change_scene_to_file("res://Main_Lab.tscn")


func fade_in():
	$SceneFade.show()
	anim.play("fade_in")
	await get_tree().create_timer(1.0).timeout
	$SceneFade.hide()

func fade_out():
	$SceneFade.show()
	$SceneFade/AudioStreamPlayer2D.play()
	anim.play("fade_out")


func _on_test_level_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	var tree := get_tree()
	tree.change_scene_to_file("res://Main_TestLevel.tscn")
