extends Area2D

signal interactable_entered(interaction_text: String)
signal interactable_exited

var _interactables: Array[Area2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		_interactables.append(area)
	#if _interactables.size() == 1 and area.has_variable("interaction_text"):
		#interactable_entered.emit(area.interaction_text)

func _on_area_exited(area: Area2D) -> void:
	if area in _interactables:
		_interactables.erase(area)
	if _interactables.is_empty():
		interactable_exited.emit()
		
func trigger_interact() -> void:
	if _interactables.is_empty():
		return
	var target := _interactables[0]
	if target and target.has_method("interact"):
		target.interact()
