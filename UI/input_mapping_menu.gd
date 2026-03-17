extends CanvasLayer

var text_size
@onready var anim = $SceneFade/Fade

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/BackButton.grab_focus()
	$HBoxContainer/VBoxController/Left.texture = load("res://UI/Buttons Pack/XBOX/LEFTSTICK.png")
	$HBoxContainer/VBoxController/Right.texture = load("res://UI/Buttons Pack/XBOX/LEFTSTICK.png")

	text_size = UiGlobals.text_size
	set_font_size_recursive(self, text_size)
	fade_in()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_font_size_recursive(node: Node, size: int):
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		set_font_size_recursive(child, size)


func _on_back_button_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://UI/settings_menu.tscn")


func fade_in():
	$SceneFade.show()
	anim.play("fade_in")
	await get_tree().create_timer(1.0).timeout
	$SceneFade.hide()

func fade_out():
	$SceneFade.show()
	anim.play("fade_out")
