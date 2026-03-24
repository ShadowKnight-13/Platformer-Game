extends Area2D

signal interacted

var interaction_text: String = "Interacted"

func interact():
	print("Object says: ", interaction_text)
	interacted.emit()
