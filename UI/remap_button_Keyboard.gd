extends Button


var action_name: String
var listening := false


func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	action_name = name
	icon = load(button[_get_current_binding()])


func _pressed() -> void:
	listening = true
	icon = null
	text = "Press a key..."


func _input(event):
	if not listening:
		return

	if event is InputEventKey and event.pressed:
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

func _apply_new_binding(event: InputEvent):
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
	
	if action_name == "move_left":
		InputMap.action_add_event(action_name, make_left_stick_left())
	if action_name == "move_right":
		InputMap.action_add_event(action_name, make_left_stick_right())

	# Update UI
	if _event_to_string(event) in button:
		#text = button[_event_to_string(event)]
		#text = _event_to_string(event)
		icon = load(button[_event_to_string(event)])
		text = ""



func _get_current_binding() -> String:
	if action_name == "" or not InputMap.has_action(action_name):
		return "Unassigned"

	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		return _event_to_string(events[0])

	return "Unassigned"


func _event_to_string(event: InputEvent) -> String:
	if event is InputEventKey:
		return event.as_text()
	return "Unknown"


var button = {
	"Escape": "res://UI/Buttons Pack/KEYBOARD/KEYS/ESC.png",
	"QuoteLeft": "res://UI/Buttons Pack/KEYBOARD/KEYS/`.png",
	"1": "res://UI/Buttons Pack/KEYBOARD/KEYS/1.png",
	"2": "res://UI/Buttons Pack/KEYBOARD/KEYS/2.png",
	"3": "res://UI/Buttons Pack/KEYBOARD/KEYS/3.png",
	"4": "res://UI/Buttons Pack/KEYBOARD/KEYS/4.png",
	"5": "res://UI/Buttons Pack/KEYBOARD/KEYS/5.png",
	"6": "res://UI/Buttons Pack/KEYBOARD/KEYS/6.png",
	"7": "res://UI/Buttons Pack/KEYBOARD/KEYS/7.png",
	"8": "res://UI/Buttons Pack/KEYBOARD/KEYS/8.png",
	"9": "res://UI/Buttons Pack/KEYBOARD/KEYS/9.png",
	"0": "res://UI/Buttons Pack/KEYBOARD/KEYS/0.png",
	"Minus": "res://UI/Buttons Pack/KEYBOARD/KEYS/-.png",
	"Equal": "res://UI/Buttons Pack/KEYBOARD/KEYS/=.png",
	"Backspace": "res://UI/Buttons Pack/KEYBOARD/KEYS/BACKSPACE.png",
	"Tab": "res://UI/Buttons Pack/KEYBOARD/KEYS/TAB.png",
	"CapsLock": "res://UI/Buttons Pack/KEYBOARD/KEYS/CAPS.png",
	"Shift": "res://UI/Buttons Pack/KEYBOARD/KEYS/SHIFT.png",
	"Ctrl": "res://UI/Buttons Pack/KEYBOARD/KEYS/CTRL.png",
	"Alt": "res://UI/Buttons Pack/KEYBOARD/KEYS/ALT.png",
	"Space": "res://UI/Buttons Pack/KEYBOARD/KEYS/SPACE.png",
	"BracketLeft": "res://UI/Buttons Pack/KEYBOARD/KEYS/[.png",
	"BracketRight": "res://UI/Buttons Pack/KEYBOARD/KEYS/].png",
	"BackSlash": "res://UI/Buttons Pack/KEYBOARD/KEYS/BACKSLASH.png",
	"Semicolon": "res://UI/Buttons Pack/KEYBOARD/KEYS/SEMICOLON.png",
	"Apostrophe": "res://UI/Buttons Pack/KEYBOARD/KEYS/APOSTROPHE.png",
	"Enter": "res://UI/Buttons Pack/KEYBOARD/KEYS/ENTER.png",
	"Comma": "res://UI/Buttons Pack/KEYBOARD/KEYS/COMMA.png",
	"Period": "res://UI/Buttons Pack/KEYBOARD/KEYS/DOT.png",
	"Slash": "res://UI/Buttons Pack/KEYBOARD/KEYS/FORWARDSLASH.png",
	"Home": "res://UI/Buttons Pack/KEYBOARD/KEYS/HOME.png",
	"End": "res://UI/Buttons Pack/KEYBOARD/KEYS/END.png",
	"Up": "res://UI/Buttons Pack/KEYBOARD/KEYS/ARROWUP.png",
	"Down": "res://UI/Buttons Pack/KEYBOARD/KEYS/ARROWDOWN.png",
	"Left": "res://UI/Buttons Pack/KEYBOARD/KEYS/ARROWLEFT.png",
	"Right": "res://UI/Buttons Pack/KEYBOARD/KEYS/ARROWRIGHT.png",
	"Q": "res://UI/Buttons Pack/KEYBOARD/KEYS/Q.png",
	"W": "res://UI/Buttons Pack/KEYBOARD/KEYS/W.png",
	"E": "res://UI/Buttons Pack/KEYBOARD/KEYS/E.png",
	"R": "res://UI/Buttons Pack/KEYBOARD/KEYS/R.png",
	"T": "res://UI/Buttons Pack/KEYBOARD/KEYS/T.png",
	"Y": "res://UI/Buttons Pack/KEYBOARD/KEYS/Y.png",
	"U": "res://UI/Buttons Pack/KEYBOARD/KEYS/U.png",
	"I": "res://UI/Buttons Pack/KEYBOARD/KEYS/I.png",
	"O": "res://UI/Buttons Pack/KEYBOARD/KEYS/O.png",
	"P": "res://UI/Buttons Pack/KEYBOARD/KEYS/P.png",
	"A": "res://UI/Buttons Pack/KEYBOARD/KEYS/A.png",
	"S": "res://UI/Buttons Pack/KEYBOARD/KEYS/S.png",
	"D": "res://UI/Buttons Pack/KEYBOARD/KEYS/D.png",
	"F": "res://UI/Buttons Pack/KEYBOARD/KEYS/ESC.png",
	"G": "res://UI/Buttons Pack/KEYBOARD/KEYS/G.png",
	"H": "res://UI/Buttons Pack/KEYBOARD/KEYS/H.png",
	"J": "res://UI/Buttons Pack/KEYBOARD/KEYS/J.png",
	"K": "res://UI/Buttons Pack/KEYBOARD/KEYS/K.png",
	"L": "res://UI/Buttons Pack/KEYBOARD/KEYS/L.png",
	"Z": "res://UI/Buttons Pack/KEYBOARD/KEYS/Z.png",
	"X": "res://UI/Buttons Pack/KEYBOARD/KEYS/X.png",
	"C": "res://UI/Buttons Pack/KEYBOARD/KEYS/C.png",
	"V": "res://UI/Buttons Pack/KEYBOARD/KEYS/V.png",
	"B": "res://UI/Buttons Pack/KEYBOARD/KEYS/B.png",
	"N": "res://UI/Buttons Pack/KEYBOARD/KEYS/N.png",
	"M": "res://UI/Buttons Pack/KEYBOARD/KEYS/M.png"
}

func make_left_stick_left() -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = JOY_AXIS_LEFT_X
	ev.axis_value = -1.0
	return ev
	
func make_left_stick_right() -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = JOY_AXIS_LEFT_X
	ev.axis_value = 1.0
	return ev
