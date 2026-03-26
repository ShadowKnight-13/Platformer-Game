extends StaticBody2D

@onready var interactable: Area2D = $interactable
@onready var anim_player: AnimationPlayer = $"Door Animator/AnimationPlayer"

@export_file("*.tscn") var level: String = ""
@export var door_open_animation: StringName = &"open"
@export var door_fallback_wait_seconds: float = 0.25

const SceneFadeScene: PackedScene = preload("res://UI/scene_fade.tscn")

var _is_transitioning := false
var fade := SceneFadeScene.instantiate()
var fade_anim: AnimationPlayer = fade.get_node("Fade")


func _ready() -> void:
	interactable.interacted.connect(_on_interact)


func _on_interact() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if level == "":
		push_warning("Door has no target_scene_path set")
		_is_transitioning = false
		return

	var main := get_tree().get_first_node_in_group("GameMain")
	if main and main.has_method("load_level"):
		main.call("load_level", level)
		return

	# Fallback: if Main isn't present (e.g. you started by running a level scene directly),
	# switch to the Main wrapper so the HUD/single-player flow remains consistent.
	var tree := get_tree()
	tree.change_scene_to_file("res://Main.tscn")
	await tree.process_frame

	var main_after := tree.get_first_node_in_group("GameMain")
	if main_after and main_after.has_method("load_level"):
		main_after.call("load_level", level)
	else:
		push_error("Door fallback: Main not found after switching to Main.tscn")
		
	if anim_player and anim_player.has_animation(door_open_animation):
		anim_player.play(door_open_animation)
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(door_fallback_wait_seconds).timeout
	(get_tree().current_scene if get_tree().current_scene else get_tree().root).add_child(fade)
	fade.show()
	fade_anim.play("fade_out")
	await fade_anim.animation_finished
		
	get_tree().change_scene_to_file(level)
