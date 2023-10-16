class_name PathfindEntityStats
extends Resource
## Resource to store the properties of an entity that uses the Platformer Pathfinding A* Algorithm

## Entity's jump height (in tilemap tiles)
var jump_height: int = 3

## Entity's horizontal jump distance (in tilemap tiles)
var jump_distance: int = 6

# Entity's vertical height (in tilemap tiles)
var height: int = 2


func _init(_jump_height: int = jump_height, _jump_distance: int = jump_distance, _height: int = height) -> void:
	jump_height = _jump_height
	jump_distance = _jump_distance
	height = _height


func _to_string() -> String:
	return "<PathfindEntityStats jump_height=" + str(jump_height) + " jump_distance=" + str(jump_distance) + " height=" + str(height) + ">"
