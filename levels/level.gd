class_name Level extends Node3D

#region Properties

static var current: Level
static func get_instance() -> Level:
	assert(current);    return current

var container: Node3D
func get_container() -> Node3D:
	assert(container);  return container

var players: Array[Player] = []
func get_player(idx: int = 0) -> Player:
	var player: Player = players[idx]
	if Game.is_dev_mode() and (not player):
		if players.is_empty(): push_error("No Players stored in the array.")
		elif idx >= players.size(): push_error("Out of bounds Player index %d." % idx)
		else: push_error("Invalid (null) Player at index %d." % idx)
	return player

#endregion
#region Virtuals


func _init() -> void:
	container = Node3D.new()
	container.name = &"InstanceContainer"
	add_child(container, true)

func _enter_tree() -> void:
	assert(current == null, "Multiple Levels in tree");  current = self
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)

func _exit_tree() -> void:
	if current == self: current = null

func _ready() -> void:
	Log.measure_end(&"load_level")


#endregion
#region Class methods

## Adds [param node] as a child to the current level's [member container].
static func add_to_scene(node: Node, gpos: Vector3) -> void:
	get_instance().container.add_child(node)
	node.global_position = gpos


#endregion
#region Signal callbacks

func _on_node_added(node: Node) -> void:
	if node is Player:
		if not node in players:
			players.append(node)
	## Detect more node types here if you like ...
	#elif node is 

func _on_node_removed(node: Node) -> void:
	if node is Player:
		players.erase(node)
	## Detect more node types here if you like ...
	#elif node is
	
#endregion
