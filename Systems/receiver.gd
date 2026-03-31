extends Node
class_name PuzzleReceiver

signal active_changed(active: bool)

enum LogicMode {
	ANY,
	ALL,
	TOGGLE
}

@export var puzzle_id: String = ""
@export var logic_mode: LogicMode = LogicMode.ANY
@export var parent_method: StringName = &""

var _source_states: Dictionary = {}
var _active: bool = false

func _ready() -> void:
	add_to_group("puzzle_target")

func on_switch_state(source_id: String, is_on: bool) -> void:
	var was_on: bool = bool(_source_states.get(source_id, false))
	_source_states[source_id] = is_on

	match logic_mode:
		LogicMode.ANY:
			_active = _compute_any()
		LogicMode.ALL:
			_active = _compute_all()
		LogicMode.TOGGLE:
			if not was_on and is_on:
				_active = not _active

	_emit_and_apply()

func _emit_and_apply() -> void:
	active_changed.emit(_active)

	if parent_method != &"" and get_parent() and get_parent().has_method(parent_method):
		get_parent().call(parent_method, _active)

func _compute_any() -> bool:
	for v in _source_states.values():
		if bool(v):
			return true
	return false

func _compute_all() -> bool:
	if _source_states.is_empty():
		return false
	for v in _source_states.values():
		if not bool(v):
			return false
	return true

func is_active() -> bool:
	return _active
