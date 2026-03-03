extends CharacterBody2D

var is_dashing: bool = false
var is_air_dive: bool = false

@onready var floor_raycast: RayCast2D = $FloorRaycast

# Updated check_for_ledge function
func check_for_ledge():
    if is_dashing and is_air_dive:
        # Current behavior when dashing and air diving
        pass
    else:
        if floor_raycast.is_colliding():
            var floor_result = floor_raycast.get_collision_point()
            if floor_result.y < global_position.y:
                # Allow teleport if the floor position is above the player's position
                teleport()  # Replace with the actual teleport logic
            else:
                print("Can't teleport downward when wall sliding near the floor.")
