extends StaticBody2D

@onready var interactable: Area2D = $interactable
@onready var sprite_2d: Sprite2D = $Sprite2D

var _used: bool = false

func _ready() -> void:
	if interactable.has_signal("interacted"):
		interactable.interacted.connect(_on_interact)

func _on_interact() -> void:
	if _used:
		return
	if sprite_2d.frame == 0:
		sprite_2d.frame = 1
	_used = true
	print("stuff")
