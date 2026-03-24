extends Node
class_name PuzzleTarget

enum LogicMode {
	ANY,
	ALL,
	TOGGLE
}

@export var puzzle_id: String = ""
@export var logic_mode: LogicMode =LogicMode.ANY

var _source_states: Dictionary = {} # source_id -> bool
var _is_active: bool = false

func on_switch_state(source_id: String, is_on: bool) -> void:
	var was_on := _source_states.get(source_id, false)
	_source_states[source_id] = is_on
	
	match logic_mode:
		LogicMode.ANY:
			_is_active = _compute_any()
		LogicMode.ALL:
			_is_active = _compute_all()
		LogicMode.TOGGLE:
			if not was_on and is_on:
				_is_active = not _is_active
	apply_active_state(_is_active)
	
func _compute_any() -> bool:
	for value in _source_states.values():
		if value:
			return true
	return false

func _compute_all() -> bool:
	if _source_states.is_empty():
		return false
	for value in _source_states.values():
		if not value:
			return false
	return true

func apply_active_state(active: bool) -> void:
	pass
