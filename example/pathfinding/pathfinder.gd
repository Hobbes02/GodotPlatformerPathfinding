extends Node2D

const DIRECTION_UP: int = 0
const DIRECTION_DOWN: int = 2
const DIRECTION_LEFT: int = 3
const DIRECTION_RIGHT: int = 4

var show_graph: bool = true
var show_path: bool = true

var graphs: Array[Dictionary] = []


func initialize(tilemap: TileMap, layer: int, stats: PathfindEntityStats) -> int:
	clear_visuals()
	var graph = AStar2D.new()
	
	graph = generate_points(graph, tilemap, layer, stats)
	graph = connect_points(graph, tilemap, layer, stats)
	
	graphs.append({
		"graph": graph, 
		"tilemap": tilemap, 
		"layer": layer, 
		"stats": stats
	})
	
	return len(graphs) - 1


func find_path(graph_id: int, from: Vector2, to: Vector2) -> Array[PathfindTarget]:
	if show_path:
		clear_visuals()
	
	var graph: AStar2D = graphs[graph_id].graph
	var tilemap: TileMap = graphs[graph_id].tilemap
	var tilemap_layer: int = graphs[graph_id].layer
	var tile_size: Vector2 = tilemap.tile_set.tile_size
	var path: Array[PathfindTarget] = []
	var from_id = graph.get_closest_point(from)
	var to_id = graph.get_closest_point(to)
	var id_path = graph.get_id_path(from_id, to_id)
	
	if len(id_path) < 1:
		return []
	
	for i in range(len(id_path)):
		var id = id_path[i]
		
		var pos: Vector2 = graph.get_point_position(id)
		
		var target = PathfindTarget.new()
		target.movement_type = target.TYPE_WALK
		target.position = pos
		target.direction = -1 if from.x < pos.x else 1
		if show_path:
			add_low_level_visual(pos, Color8(0, 0, 128))
		
		if i != 0:
			var prev_pos: Vector2 = graph.get_point_position(id_path[i - 1])
			
			target.direction = -1 if pos.x < prev_pos.x else 1
			
			var is_walkable = is_pos_in_tilemap(
				Vector2(pos.x + tile_size.x if pos.x < prev_pos.x else pos.x - tile_size.x, pos.y + tile_size.y), 
				tilemap, 
				tilemap_layer
			)
			var distance = abs(pos.x - prev_pos.x)
			
			if pos.y < prev_pos.y or (pos.y - prev_pos.y < 4 and not is_walkable) or (pos.y > prev_pos.y and distance > tile_size.x * 1.5):
				var jump = PathfindTarget.new()
				jump.movement_type = jump.TYPE_JUMP
				jump.direction = -1 if pos.x < prev_pos.x else 1
				jump.position = pos
				path.append(jump)
				if show_path:
					add_low_level_visual(pos, Color8(128, 0, 0))
			elif pos.y > prev_pos.y:
				var fall = PathfindTarget.new()
				fall.movement_type = target.TYPE_WALK
				fall.position = Vector2(pos.x, prev_pos.y)
				fall.direction = -1 if pos.x < prev_pos.x else 1
				path.append(fall)
				if show_path:
					add_low_level_visual(pos, Color8(0, 128, 0))
			if show_path:
				add_line(prev_pos, pos)
		
		path.append(target)
	
	return path


func generate_points(graph: AStar2D, tilemap: TileMap, layer: int, stats: PathfindEntityStats) -> AStar2D:
	var cells: Array = tilemap.get_used_cells(layer)
	
	for cell in cells:
		var above = Vector2i(cell.x, cell.y - 1)
		var type = get_cell_type(cells, cell, stats)
		
		if type != null and type != [0, 0]:
			graph = add_point(above, tilemap, graph)
			
			if type[0] == -1:
				var res = virtual_tile_raycast([cells], Vector2i(cell.x - 1, cell.y), 50, DIRECTION_DOWN)
				if res != null:
					graph = add_point(Vector2i(res.x, res.y - 1), tilemap, graph)
			if type[1] == -1:
				var res = virtual_tile_raycast([cells], Vector2i(cell.x + 1, cell.y), 50, DIRECTION_DOWN)
				if res != null:
					graph = add_point(Vector2i(res.x, res.y - 1), tilemap, graph)
	
	return graph


func connect_points(graph: AStar2D, tilemap: TileMap, layer: int, stats: PathfindEntityStats) -> AStar2D:
	var tilemap_cells: Array = tilemap.get_used_cells(layer)
	var point_cells: Array = []
	var cell_size: Vector2 = tilemap.tile_set.tile_size
	
	for point in graph.get_point_ids():
		var point_cell = tilemap.local_to_map(tilemap.to_local(graph.get_point_position(point)))
		point_cells.append(Vector2i(point_cell.x, point_cell.y + 1))
	
	for i in range(len(graph.get_point_ids())):
		var id = graph.get_point_ids()[i]
		var point_cell = point_cells[i]
		
		# Find close right neighbor
		for j in range(1, 33):
			var c = Vector2i(point_cell.x + j, point_cell.y)
			
			if get_cell_type(tilemap_cells, c, stats) in [null, [-1, -1]]:
				break
			if c in point_cells:
				graph.connect_points(id, graph.get_point_ids()[point_cells.find(c)])
				if show_graph:
					add_line(graph.get_point_position(id), graph.get_point_position(graph.get_point_ids()[point_cells.find(c)]))
				break
		
		# Find drop-down neighbor(s)
		var type = get_cell_type(tilemap_cells, point_cell, stats)
		if type[0] == -1:  # left drop-down
			var res = virtual_tile_raycast([tilemap_cells, point_cells], Vector2i(point_cell.x - 1, point_cell.y), 64, DIRECTION_DOWN)
			if res != null and res in point_cells:
				graph.connect_points(id, graph.get_point_ids()[point_cells.find(res)], graph.get_point_position(id).distance_to(graph.get_point_position(graph.get_point_ids()[point_cells.find(res)])) <= (stats.jump_height * tilemap.tile_set.tile_size.y))
				if show_graph:
					add_line(graph.get_point_position(id), graph.get_point_position(graph.get_point_ids()[point_cells.find(res)]))
		if type[1] == -1:  # right drop-down
			var res = virtual_tile_raycast([tilemap_cells, point_cells], Vector2i(point_cell.x + 1, point_cell.y), 64, DIRECTION_DOWN)
			if res != null and res in point_cells:
				graph.connect_points(id, graph.get_point_ids()[point_cells.find(res)], graph.get_point_position(id).distance_to(graph.get_point_position(graph.get_point_ids()[point_cells.find(res)])) <= (stats.jump_height * tilemap.tile_set.tile_size.y))
				if show_graph:
					add_line(graph.get_point_position(id), graph.get_point_position(graph.get_point_ids()[point_cells.find(res)]))
		
		# Find jumpable neighbors
		if type[0] == -1:
			for y in range(stats.jump_height):
				var res = virtual_tile_raycast([point_cells, tilemap_cells], Vector2i(point_cell.x, point_cell.y - y), stats.jump_distance - y, DIRECTION_LEFT, is_cell_valid, stats)
				if res != null and res in point_cells:
					graph.connect_points(id, graph.get_point_ids()[point_cells.find(res)])
					if show_graph:
						add_line(graph.get_point_position(id), graph.get_point_position(graph.get_point_ids()[point_cells.find(res)]))
		if type[1] == -1:
			for y in range(stats.jump_height):
				var res = virtual_tile_raycast([point_cells, tilemap_cells], Vector2i(point_cell.x, point_cell.y - y), stats.jump_distance - y, DIRECTION_RIGHT, is_cell_valid, stats)
				if res != null and res in point_cells:
					graph.connect_points(id, graph.get_point_ids()[point_cells.find(res)])
					if show_graph:
						add_line(graph.get_point_position(id), graph.get_point_position(graph.get_point_ids()[point_cells.find(res)]))
		
	return graph


func add_point(cell: Vector2i, map: TileMap, graph: AStar2D) -> AStar2D:
	var pos = map.to_global(map.map_to_local(cell))
	if len(graph.get_point_ids()) > 0:
		if graph.get_point_position(graph.get_closest_point(pos)) == pos:
			return graph
	
	graph.add_point(graph.get_available_point_id(), pos)
	add_visual(cell, map)
	return graph


func add_visual(cell: Vector2i, map: TileMap) -> void:
	if not show_graph:
		return
	var r = $Reference.duplicate()
	r.global_position = map.to_global(map.map_to_local(cell))
	add_child(r)
	r.show()


func add_low_level_visual(pos: Vector2, color: Color) -> void:
	var r: Sprite2D = $Reference.duplicate()
	r.global_position = pos
	r.modulate = color
	add_child(r)
	r.show()


func add_line(from: Vector2, to: Vector2) -> void:
	var l = $Line2D.duplicate()
	l.points = [from, to]
	add_child(l)
	l.show()


func clear_visuals() -> void:
	for child in get_children():
		if "@" in child.name:
			child.queue_free()


func virtual_tile_raycast(cell_arrays: Array[Array], start: Vector2i, distance: int, direction: int, cell_check: Variant = null, stats: Variant = null) -> Variant:
	for i in range(1, distance - 1):
		var cell: Vector2i = start
		match direction:
			DIRECTION_UP:
				cell.y = start.y - i
			DIRECTION_DOWN:
				cell.y = start.y + i
			DIRECTION_LEFT:
				cell.x = start.x - i
			DIRECTION_RIGHT:
				cell.x = start.x + i
		
		if cell_check != null:
			if not cell_check.call(cell_arrays, cell, stats):
				return null
			else:
				for cells in cell_arrays:
					if cell in cells:
						return cell
		else:
			for cells in cell_arrays:
				if cell in cells:
					return cell
	
	return null


func is_pos_in_tilemap(pos: Vector2, tilemap: TileMap, layer: int) -> bool:
	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(pos))
	
	return cell in tilemap.get_used_cells(layer)


func is_cell_valid(cell_arrays: Array[Array], cell: Vector2i, stats: PathfindEntityStats) -> bool:
	for cells in cell_arrays:
		for i in range(1, stats.height + 1):
			if Vector2i(cell.x, cell.y - i) in cells:
				return false
	return true


func get_cell_type(cells: Array, cell: Vector2i, stats: PathfindEntityStats) -> Variant:
	var res: Array = [0, 0]
	
	for i in range(1, stats.height + 1):
		if Vector2i(cell.x, cell.y - i) in cells:
			return null
	
	if Vector2i(cell.x - 1, cell.y - 1) in cells or Vector2i(cell.x - 1, cell.y - 2) in cells:
		res[0] = 1
	elif not Vector2i(cell.x - 1, cell.y) in cells:
		res[0] = -1
	
	if Vector2i(cell.x + 1, cell.y - 1) in cells or Vector2i(cell.x + 1, cell.y - 2) in cells:
		res[1] = 1
	elif not Vector2i(cell.x + 1, cell.y) in cells:
		res[1] = -1
	
	return res


class Agent:
	var speed: int
	var gravity: int
	var jump_velocity: int
	var margin: int
	var finished_callback: Callable
	var current_point: int = -1
	var path: Array[PathfindTarget] = []
	
	func _init(_speed: int, _gravity: int, _jump_velocity: int, _margin: int, _finished_callback: Callable = Callable()) -> void:
		self.speed = _speed
		self.gravity = _gravity
		self.jump_velocity = _jump_velocity
		self.margin = _margin
		
		self.finished_callback = _finished_callback
		
		self.current_point = -1
		self.path = []
	
	func compute_velocity(velocity: Vector2, pos: Vector2, is_on_floor: bool, delta_time: float) -> Vector2:
		if self.current_point == -1:
			return Vector2(0, velocity.y + self.gravity if not is_on_floor else 0)
		if not is_on_floor:
			velocity.y += self.gravity * delta_time
		var target = self.path[self.current_point]
		var target_pos = target.position
		advance_point_if_required(pos)
		
		match target.movement_type:
			PathfindTarget.TYPE_JUMP:
				if is_on_floor and pos.y >= target_pos.y:
					velocity.y = self.jump_velocity
				elif abs(pos.x - target_pos.x) > self.margin:
					velocity.x = self.speed if pos.x < target_pos.x else -self.speed
				else:
					velocity.x = 0
			PathfindTarget.TYPE_WALK:
				velocity.x = self.speed if pos.x < target_pos.x else -self.speed
		
		return velocity
	
	func advance_point_if_required(pos: Vector2) -> void:
		var target = self.path[self.current_point]
		
		if self.current_point <= len(self.path) - 2:
			var next_target = self.path[self.current_point + 1]
			
			if ((target.position.x > pos.x and next_target.position.x < pos.x) or\
			(target.position.x < pos.x and next_target.position.x > pos.x)) and\
			(abs(target.position.y - next_target.position.y) < (self.margin * 2)):
				next_point()
		
		if target.movement_type == PathfindTarget.TYPE_JUMP:
			if pos.distance_to(target.position) < (self.margin * 1.2):
				next_point()
		elif pos.distance_to(target.position) < self.margin:
			next_point()
	
	func next_point() -> void:
		self.current_point += 1
		
		if self.current_point >= len(self.path):
			self.current_point = -1
			self.path = []
			
			if self.finished_callback != Callable():
				self.finished_callback.call()
	
	func follow_path(path_to_follow: Array[PathfindTarget]) -> void:
		if len(path_to_follow) <= 0:
			return
		self.path = path_to_follow
		self.current_point = 0
