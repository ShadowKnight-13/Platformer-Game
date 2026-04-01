extends HBoxContainer

@onready var _label: Label = $Label


func _ready() -> void:
	if not CollectibleManager.count_changed.is_connected(_on_count_changed):
		CollectibleManager.count_changed.connect(_on_count_changed)
	_apply_text(CollectibleManager.total_collected)
	if has_node("/root/UiGlobals"):
		add_theme_font_size_override("font_size", UiGlobals.text_size)


func _on_count_changed(new_total: int) -> void:
	_apply_text(new_total)


func _apply_text(n: int) -> void:
	if _label:
		_label.text = "People saved: %d" % n
