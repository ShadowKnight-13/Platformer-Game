extends StaticBody2D

@onready var intractable: Area2D = $interactable
@onready var anim_player: AnimationPlayer = $"Lever Animator/AnimationPlayer"

var is_on: bool = false

signal toggled(on:bool)

func _ready() -> void:
	intractable.interacted.connect(_on_interact)
	_update_animation()

func _on_interact() -> void:
	is_on = !is_on
	_update_animation()
	toggled.emit(is_on)

func _update_animation() -> void:
	if is_on:
		anim_player.play("on")
	else:
		anim_player.play("off")
