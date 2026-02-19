extends Area2D

signal interacted

@export var interaction_text: String = "Heal"

func interact():
	print("Object says: ", interaction_text)
	interacted.emit()
