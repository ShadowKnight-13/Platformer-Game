extends Button


var action_name: String
var listening := false

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	action_name = name
	if UiGlobals.controller_buttons == 0:
		icon = load(xboxButton[_get_current_binding()])
	elif UiGlobals.controller_buttons == 1:
		icon = load(psButton[_get_current_binding()])


func _pressed() -> void:
	listening = true
	text = "Press a button..."
	icon = null


func _input(event):
	if not listening:
		return

	if event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		_apply_new_binding(event)
	if event is InputEventJoypadMotion and event.axis_value > 0.5 and event.axis > 3:
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
	print(event)

	# Update UI
	if UiGlobals.controller_buttons == 0:
		if _event_to_string(event) in xboxButton:
			icon = load(xboxButton[_event_to_string(event)])
			text = ""
	elif UiGlobals.controller_buttons == 1:
		if _event_to_string(event) in psButton:
			icon = load(psButton[_event_to_string(event)])
			text = ""


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
	if event is InputEventJoypadMotion:
		print(event.axis)
		return "Joypad %d" % event.axis
	return "Unknown"


var xboxButton = {
	"Joypad 0": "res://UI/Buttons Pack/XBOX/A.png",
	"Joypad 1": "res://UI/Buttons Pack/XBOX/B.png",
	"Joypad 2": "res://UI/Buttons Pack/XBOX/X.png",
	"Joypad 3": "res://UI/Buttons Pack/XBOX/Y.png",
	"Joypad 4": "res://UI/Buttons Pack/XBOX/LT.png",
	"Joypad 5": "res://UI/Buttons Pack/XBOX/RT.png",
	"Joypad 6": "res://UI/Buttons Pack/XBOX/START.png",
	"Joypad 7": "res://UI/Buttons Pack/XBOX/LEFTSTICK.png",
	"Joypad 8": "res://UI/Buttons Pack/XBOX/RIGHTSTICK.png",
	"Joypad 9": "res://UI/Buttons Pack/XBOX/L.png",
	"Joypad 10": "res://UI/Buttons Pack/XBOX/R.png",
	"Joypad 11": "res://UI/Buttons Pack/XBOX/CONTROLPADUP.png",
	"Joypad 12": "res://UI/Buttons Pack/XBOX/CONTROLPADDOWN.png",
	"Joypad 13": "res://UI/Buttons Pack/XBOX/CONTROLPADLEFT.png",
	"Joypad 14": "res://UI/Buttons Pack/XBOX/CONTROLPADRIGHT.png",
}

var psButton = {
	"Joypad 0": "res://UI/Buttons Pack/PS4/X.png",
	"Joypad 1": "res://UI/Buttons Pack/PS4/CIRCLE.png",
	"Joypad 2": "res://UI/Buttons Pack/PS4/SQUARE.png",
	"Joypad 3": "res://UI/Buttons Pack/PS4/TRIANGLE.png",
	"Joypad 4": "res://UI/Buttons Pack/PS4/L2.png",
	"Joypad 5": "res://UI/Buttons Pack/PS4/R2.png",
	"Joypad 6": "res://UI/Buttons Pack/PS4/START.png",
	"Joypad 7": "res://UI/Buttons Pack/PS4/LEFTSTICK.png",
	"Joypad 8": "res://UI/Buttons Pack/PS4/RIGHTSTICK.png",
	"Joypad 9": "res://UI/Buttons Pack/PS4/L1.png",
	"Joypad 10": "res://UI/Buttons Pack/PS4/R2.png",
	"Joypad 11": "res://UI/Buttons Pack/PS4/CONTROLPADUP.png",
	"Joypad 12": "res://UI/Buttons Pack/PS4/CONTROLPADDOWN.png",
	"Joypad 13": "res://UI/Buttons Pack/PS4/CONTROLPADLEFT.png",
	"Joypad 14": "res://UI/Buttons Pack/PS4/CONTROLPADRIGHT.png"
}
