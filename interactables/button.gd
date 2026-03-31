extends StaticBody2D

enum LinkMode {
	MANUAL,
	CHANNEL,
	BOTH
}


@onready var interactable: Area2D = $interactable
@onready var anim_player: AnimationPlayer = $"Button Animator/AnimationPlayer"

@export var source_id: String = ""
@export var puzzle_id: String = ""
@export var Link_mode: LinkMode = LinkMode.BOTH
@export var target_paths: Array[NodePath] = []

var is_pressed: bool = false

signal pressed
signal released

func _ready() -> void:
	interactable.interacted.connect(_on_interact)
	_update_animation()

func _on_interact() -> void:
	is_pressed = !is_pressed
	_update_animation()

	if is_pressed:
		pressed.emit()
	else:
		released.emit()

	_broadcast_state()

func _update_animation() -> void:
	if is_pressed:
		anim_player.play("pressed")
	else:
		anim_player.play("RESET")
		
func _broadcast_state() -> void:
	var sid := source_id if source_id != "" else str(get_path())
	var targets: Array = _collect_targets()
	
	for t in targets:
		if t and t.has_method("on_switch_state"):
			t.on_switch_state(sid, is_pressed)
func _collect_targets() -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	if Link_mode == LinkMode.MANUAL or Link_mode == LinkMode.BOTH:
		for p in target_paths:
			var n := get_node_or_null(p)
			if n and not seen.has(n):
				seen[n] = true
				result.append(n)
	for n in get_tree().get_nodes_in_group("puzzle_target"):
		if not n.has_method("on_switch_state"):
			continue
		if "puzzle_id" in n and n.puzzle_id == puzzle_id:
			result.append(n)
	return result
