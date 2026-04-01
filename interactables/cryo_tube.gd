extends StaticBody2D

@onready var interactable: Area2D = $interactable
@onready var anim_player: AnimationPlayer = $"Node2D/AnimationPlayer"
@onready var _sprite: Sprite2D = $"Node2D/Sprite2D"

var used: bool = false
var _persist_key: String = ""


func _ready() -> void:
	_persist_key = _persistence_key()
	interactable.interacted.connect(_on_interact)
	if _persist_key != "" and CryoState.is_opened(_persist_key):
		_apply_already_opened()


func _persistence_key() -> String:
	var o := owner
	if o == null:
		push_warning("cryo_tube: no owner, persistence skipped (%s)" % name)
		return ""
	var sp := o.scene_file_path
	if sp == "":
		push_warning("cryo_tube: owner has no scene_file_path (%s)" % name)
		return ""
	return "%s::%s" % [sp, str(o.get_path_to(self))]


func _apply_already_opened() -> void:
	used = true
	interactable.set_deferred("monitoring", false)
	interactable.set_deferred("monitorable", false)
	if anim_player.has_animation("release"):
		var anim := anim_player.get_animation("release")
		anim_player.play("release")
		if anim:
			anim_player.seek(anim.length, true)
		anim_player.pause()
	elif _sprite:
		_sprite.frame = 22


func _on_interact() -> void:
	if used:
		return
	used = true
	if _persist_key != "":
		CryoState.mark_opened(_persist_key)
	CollectibleManager.register_pickup(1)

	if anim_player.has_animation("release"):
		anim_player.play("release")
