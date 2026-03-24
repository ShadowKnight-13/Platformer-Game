extends AudioStreamPlayer2D

var current_scene_name := ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	play(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_scene_changed():
	var scene := get_tree().current_scene
	var scene_name := scene.name

	if scene_name == "MainMenu":
		$Black.show()
		if playing == true:
			return
		else:
			play(0)
	elif scene_name == "LevelSelect":
		return
	elif scene_name == "SettingsMenu":
		return
	elif scene_name == "InputMappingMenu":
		return
	else:
		$Black.hide()
		stop()
