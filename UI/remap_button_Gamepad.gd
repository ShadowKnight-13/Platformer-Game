extends Button


var action_name: String
var listening := false

func _ready():
	action_name = name
	text = _get_current_binding()


func _pressed() -> void:
	listening = true
	text = "Press a button..."


func _input(event):
	if not listening:
		return

	if event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		_apply_new_binding(event)


const UI_ACTIONS := [
	"ui_accept",
	"ui_select",
	"ui_cancel",
	"ui_up",
	"ui_down",
	"ui_left",
	"ui_right",
]

func _apply_new_binding(event):
	listening = false

	# Check if this event is already used by another non-UI action
	for action in InputMap.get_actions():
		if action == action_name:
			continue
		if action in UI_ACTIONS:
			continue

		for e in InputMap.action_get_events(action):
			if event.is_match(e):
				if !action.begins_with("ui_"):
					text = "Already assigned!"
					return

	# Remove old bindings
	for old_event in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, old_event)

	# Add new binding
	InputMap.action_add_event(action_name, event)

	# Update UI
	text = _event_to_string(event)



func _get_current_binding() -> String:
	if action_name == "" or not InputMap.has_action(action_name):
		return "Unassigned"

	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		return _event_to_string(events[0])

	return "Unassigned"


func _event_to_string(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		return "Joypad %d" % event.button_index
	return "Unknown"
