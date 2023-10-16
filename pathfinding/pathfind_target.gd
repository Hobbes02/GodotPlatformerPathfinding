class_name PathfindTarget
extends Resource
## A basic resource describing a target point for a pathfinding entity

## types of movement
const TYPE_WALK: int = 0
const TYPE_JUMP: int = 1

## movement type to arrive at this target
var movement_type: int = 0

## direction to jump/walk/fall in
var direction: int = 0

## target position
var position: Vector2

func _to_string() -> String:
	return "<PathfindTarget movement_type=" + ("TYPE_WALK" if movement_type == 0 else "TYPE_JUMP") + (" direction=" + str(direction) if movement_type == TYPE_JUMP else " position=" + str(position)) + ">"
