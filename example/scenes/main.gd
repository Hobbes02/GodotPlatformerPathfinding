extends Node2D

var graph_id: int

@onready var tilemap: TileMap = $TileMap
@onready var agent: CharacterBody2D = $Agent


func _ready() -> void:
	# create the stats for the pathfinding agent
	var stats = PathfindEntityStats.new()
	stats.height = 2
	stats.jump_distance = 8
	stats.jump_height = 3
	
	# initialize the pathfinding algorithm and store the id
	graph_id = Pathfinder.initialize(tilemap, 0, stats)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		var path: Array[PathfindTarget] = Pathfinder.find_path(
			graph_id, 
			agent.global_position,  # start
			get_global_mouse_position()  # end
		)
		agent.pathfind(path)
