extends Node

## Remembers which cryo tubes were opened this run (survives Main level reinstantiate on death).

var _opened: Dictionary = {}


func mark_opened(key: String) -> void:
	if key == "":
		return
	_opened[key] = true


func is_opened(key: String) -> bool:
	if key == "":
		return false
	return _opened.has(key)


func clear_all() -> void:
	_opened.clear()
