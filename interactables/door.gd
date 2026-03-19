extends StaticBody2D

@onready var interactable: Area2D = $interactable

@export_file("*.tscn") var level: String = ""

func _ready() -> void:
	interactable.interacted.connect(_on_interact)


func _on_interact() -> void:
	if level == "":
		push_warning("Door has no target_scene_path set")
		return

	var main := get_tree().get_first_node_in_group("GameMain")
	if main and main.has_method("load_level"):
		main.call("load_level", level)
		return

	# Fallback: if Main can't be found for some reason, keep old scene reload behavior.
	get_tree().change_scene_to_file(level)
