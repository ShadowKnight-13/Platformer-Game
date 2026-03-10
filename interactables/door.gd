extends StaticBody2D

@onready var interactable: Area2D = $interactable

@export_file("*.tscn") var level: String = ""

func _ready() -> void:
	interactable.interacted.connect(_on_interact)


func _on_interact() -> void:
	if level == "":
		push_warning("Door has no target_scene_path set")
		return
		
	get_tree().change_scene_to_file(level)
