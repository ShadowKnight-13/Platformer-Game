# Updated check_for_ledge function

# Assuming this is part of a GDScript file

func check_for_ledge():
    if is_dashing and is_air_dive:
        # Current behavior when dashing and air diving
        pass
    else:
        if floor_raycast.is_colliding():
            var floor_result = floor_raycast.get_collision_point()
            if floor_result.position.y < global_position.y:
                # Allow teleport if the floor position is above the player's position
                teleport()  # Replace with the actual teleport logic
            else:
                print("Can’t teleport downward when wall sliding near the floor.")