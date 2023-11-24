# GodotPlatformerPathfinding
A simple system to add pathfinding to your platformer game in Godot 4.

# Docs
## Adding to your project
Download the project or clone it, then copy the "pathfinding" directory into your Godot project.

## Using the Addon
This addon adds a "Pathfinder" autoload to your game. This is the autoload you'll be interacting with when using the addon.

### Initializing
Create a `PathfindingEntityStats` resource to store information about the node that will be using the pathfinding algorithm.
(All units in the `PathfindingEntityStats` resource are tilemap tiles)
```
var stats = PathfindingEntityStats.new(jump_height, jump_distance, height)
```
Now, you're ready to initialize the addon. Call
```
var id = Pathfinder.initialize(tilemap, layer, stats)
```
with tilemap being your tilemap, and layer being the integer value for the tilemap layer you want the pathfinding system to avoid.
`id` will be an integer representing the id of the graph you've initialized. Make sure to store this value for later.

### Getting a Path
Now that you've initialized the addon, you can get the path between two points. Do this by calling
```
var path = Pathfinder.find_path(id, start, end)
```
`path` will be set to an Array of `PathfindTarget`s. Check the reference to find out how to use them.

### Creating an Agent

> Disclaimer: The Agent movement isn't very clean right now, and requires a lot of tweaking settings and seeing what happens. I'm working on a better path following algorithms, but until then, it needs a lot more work modifying settings to get it smoothed out.

After the path's been created, you'll want something to follow it. For this you can set up an Agent.
Create an Agent like this:
```
var agent = Pathfinder.Agent.new(speed, gravity, jump_velocity, margin)
```
`margin` is how many pixels from the point the Agent's trying to reach it has to be to consider itself there. A larger margin means the Agent will be less accurate, but can cause it to overshoot the target.

### Following a Path
To make an Agent follow a path, call its `follow_path` method with the only argument being the path to follow.
Then, in the `CharacterBody2D` that you want to move, use the `compute_velocity` method, like this:
```
func _physics_process(delta: float) -> void:
    velocity = computer.compute_velocity(velocity, global_position, is_on_floor(), delta)
    move_and_slide()
```

# Reference
## Pathfinder
### properties
```
bool show_graph = false
if true, the pathfinding graph will be shown after initializing.

bool show_path = false
if true, the path will be drawn as a series of points and lines after calling find_path()

Array[Dictionary] graphs = []
an Array storing data for every A* graph created
to access the actual graph created by the initialize() function, use Pathfinder.graphs[graph_id]
```
### methods
```
int initialize(tilemap: TileMap, layer: int, stats: PathfindEntityStats)
initializes the graph with points following the tilemap.
returns the ID of your graph, to be used in find_path()

Array[PathfindTarget] find_path(graph_id: int, from: Vector2, to: Vector2)
finds and returns a path of PathfindTargets from a start point to an end.

AStar2D generate_points(AStar2D graph, TileMap tilemap, int layer, PathfindEntityStats stats)
takes an AStar2D graph and adds points to it following a simple algorithm.
returns the modified graph

AStar2D connect_points(AStar2D graph, TileMap tilemap, int layer, PathfindEntityStats stats)
takes a AStar2D graph and connects the points on it, returning the modified graph
```

## PathfindEntityStats
### properties
```
int jump_height = 3
default jump height value in tilemap tiles

int jump_distance = 6
the distance the agent can jump in a straight line (in tilemap tiles)

int height = 2
the height of the agent (in tilemap tiles)

```

## PathfindTarget
### properties
```
const int TYPE_WALK = 0
movement type for walking to a point

const int TYPE_JUMP = 1
movement type for jumping to a point

int movement_type = 0
the type of movement towards this point (stored as TYPE_WALK or TYPE_JUMP)

int direction = 0
the direction from the previous point to this one (-1 for left, 1 for right)

Vector2 position = (0, 0)
the position of this point
```

## Agent
### properties
```
int speed
the speed the agent moves at

int jump_velocity
the velocity applied to the agent when jumping
because of how the velocity is applied, this value should always be negative

int gravity
the gravity applied to the agent

int margin
how close the agent can be to a point to consider it there (in pixels)

Callable finished_callback
an optional callable, called when the agent reaches its destination

int current_point
used internally to keep track of the position along the path

Array[PathfindTarget] path
used internally to keep track of the path
```

### methods
```
Vector2 compute_velocity(Vector2 velocity, Vector2 position, bool is_on_floor, float delta_time)
used to find the velocity of an agent while following a path.
for the velocity, provide the built-in velocity property of any CharacterBody2D
for the position, provide global_position
for is_on_floor, call the CharacterBody2D method of the same name and provide the result
and for delta_time, use the delta argument to the _physics_process() function


void follow_path(Array[PathfindTarget] path)
sets the path for the agent to follow
use Pathfinder.find_path to get the path to follow
```
