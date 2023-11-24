extends CharacterBody2D


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_velocity: int = -350.0
var speed: int = 300.0

@onready var computer = Pathfinder.Agent.new(speed, gravity, jump_velocity, 8)


func _physics_process(delta: float) -> void:
	velocity = computer.compute_velocity(velocity, global_position, is_on_floor(), delta)
	
	move_and_slide()


func pathfind(pathfinding_path: Array[PathfindTarget]) -> void:
	computer.follow_path(pathfinding_path)
