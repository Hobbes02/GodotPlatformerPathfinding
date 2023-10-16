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

## Getting a Path
Now that you've initialized the addon, you can get the path between two points. Do this by calling
```
var path = Pathfinder.find_path(id, start, end)
```
`path` will be set to an Array of `PathfindTarget`s. Check the reference to find out how to use them.

# Reference
## Pathfinder
### properties
```
bool show_graph = false
if true, the pathfinding graph will be shown after initializing.

bool show_path = false
if true, the path will be drawn as a series of points and lines after calling find_path()

Array[Dictionary] graphs = []
an Array storing data for every A* graph created. Meant for internal use
```
### methods
```
int initialize(tilemap: TileMap, layer: int, stats: PathfindEntityStats)
initializes the graph with points following the tilemap.
returns the ID of your graph, to be used in find_path()

Array[PathfindTarget] find_path(graph_id: int, from: Vector2, to: Vector2)
finds and returns a path of PathfindTargets from a start point to an end.
```

## PathfindEntityStats
### properties
```
int jump_height = 3
default jump height value in tilemap tiles

int jump_distance = 6
the distance your charater can jump straight-on (in tilemap tiles)

int height = 2
the height of your character (in tilemap tiles)

```

## PathfindTarget
## properties
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
