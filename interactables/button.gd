extends StaticBody2D

@onready var interactable: Area2D = $interactable
@onready var anim_player: AnimationPlayer = $"Button Animator/AnimationPlayer"

var is_pressed

signal pressed
signal released

func _ready() -> void:
	interactable.interacted.connect(_on_interact)
	_update_animation()

func _on_interact() -> void:
	is_pressed= !is_pressed
	_update_animation()
	
	if is_pressed:
		pressed.emit()
	else:
		released.emit()

func _update_animation() -> void:
	if is_pressed:
		anim_player.play()
	else:
		anim_player.play()
