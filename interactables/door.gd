extends StaticBody2D

@onready var interactable: Area2D = $interactable
@onready var anim_player: AnimationPlayer = $"Door Animator/AnimationPlayer"

@export_file("*.tscn") var level: String = ""
@export var door_open_animation: StringName = &"open"
@export var door_fallback_wait_seconds: float = 0.25

const SceneFadeScene: PackedScene = preload("res://UI/scene_fade.tscn")

var _is_transitioning: bool = false

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

	# 1) Door opens while this node is still in the tree.
	if anim_player and anim_player.has_animation(door_open_animation):
		anim_player.play(door_open_animation)
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(door_fallback_wait_seconds).timeout

	# 2) Fade out (new instance each time — avoids duplicate parenting).
	var fade: CanvasLayer = SceneFadeScene.instantiate()
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(fade)

	var fade_anim: AnimationPlayer = fade.get_node("Fade")
	fade.show()
	fade_anim.play("fade_out")
	await fade_anim.animation_finished
	fade.queue_free()

	# 3) Load next level (may free this door).
	var main: Node = get_tree().get_first_node_in_group("GameMain")
	if main and main.has_method("load_level"):
		main.call("load_level", level)
		return

	var tree: SceneTree = get_tree()
	tree.change_scene_to_file("res://Main.tscn")
	await tree.process_frame

	var main_after: Node = tree.get_first_node_in_group("GameMain")
	if main_after and main_after.has_method("load_level"):
		main_after.call("load_level", level)
	else:
		var resolved: String = _resolve_level_path(level)
		if resolved != "":
			tree.change_scene_to_file(resolved)
		else:
			push_error("Door: could not resolve level and Main.load_level unavailable")

	_is_transitioning = false

func _resolve_level_path(level_ref: String) -> String:
	if level_ref == "":
		return ""
	if level_ref.begins_with("uid://"):
		var uid_id: int = ResourceUID.text_to_id(level_ref)
		if ResourceUID.has_id(uid_id):
			return ResourceUID.get_id_path(uid_id)
		return ""
	if level_ref.begins_with("res://"):
		return level_ref
	return ""
