extends StaticBody2D

@onready var interactable: Area2D = $interactable
@onready var anim_player: AnimationPlayer = $"Node2D/AnimationPlayer"

var used:bool = false

func _ready() -> void:
	interactable.interacted.connect(_on_interact)

func _on_interact() -> void:
	if used:
		return
	used = true
	
	if anim_player.has_animation("release"):
		anim_player.play("release")
