extends Area2D


# This variable stores a message we can change in the Inspector
@export var interaction_text: String = "Heal" 

# This function will be called by the Player script
func interact():
	print("Object says: ", interaction_text)
	# You could add logic here to open a chest or play a sound
