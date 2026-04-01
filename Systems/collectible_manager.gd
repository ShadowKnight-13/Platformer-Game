extends Node

## Run-wide total of people saved (cryo tube interactions). Autoload persists across scenes.

var total_collected: int = 0

signal count_changed(new_total: int)


func register_pickup(amount: int = 1) -> void:
	if amount <= 0:
		return
	total_collected += amount
	count_changed.emit(total_collected)


## Call from Main when switching levels if you want per-level-only counting later.
func reset_run() -> void:
	total_collected = 0
	count_changed.emit(total_collected)
