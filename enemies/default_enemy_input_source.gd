class_name DefaultEnemyInputSource
extends InputSource

# This is the primary place to put enemy AI. Here if it can be
# shared in a configurable way (export vars) or in an override script

# We're trying to frame all AI as fake controller inputs: move, attack,
# dash, or special. It's very possible we'll need to add a few extra
# options for bosses, though.

signal retarget(target_gpos: Vector3)

## How frequently does the enemy choose a new target position
## It does this by finding the closest player and remembering its
## position. If the player moves it won't change that target position
## Until the next retargeting event
@export var retarget_min_seconds := 0.1
@export var retarget_max_seconds := 0.1

## When a new target is chosen and the enemy is rotating towards it
## at whatever the turn_speed is in its stat block, can it also move
## forward?
@export var move_speed_while_retargeting := 1.0

@export var attack_min_seconds := 0.0
@export var attack_max_seconds := 0.0

@export_group("Optional Overrides")
@export var host: Node3D
@export var host_body: BodyPartContainer

var target_node: Node3D
var target_gpos: Vector3
var target_dir: Vector3
var cur_dir: Vector3


func _ready() -> void:
	if not host and get_parent() is Node3D:
		host = get_parent()
	if host and not host_body:
		if host is Enemy:
			host_body = host.body
		if not host_body:
			host_body = host.get_node_or_null("Body")
	_start_attack_timer.call_deferred()
	_start_retarget_timer.call_deferred()


func _retarget() -> void:
	target_node = _find_nearest_player()
	if target_node:
		target_gpos = target_node.global_position
		target_dir = host.global_position.direction_to(target_gpos)
	else:
		target_dir = Vector3.ZERO
	retarget.emit(target_gpos)


func _find_nearest_player() -> Node3D:
	var closest: Node3D
	var min_dist: float = 1_000_000.0
	if not get_tree():
		return null
	for n in get_tree().get_nodes_in_group("player"):
		var dist := host.global_position.distance_squared_to(n.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = n
	return closest


func _process(delta: float) -> void:
	if not cur_dir.is_equal_approx(target_dir):
		var adjusted_target_dir = target_dir
		if not cur_dir.normalized().is_equal_approx(target_dir):
			adjusted_target_dir = target_dir * move_speed_while_retargeting
		cur_dir = cur_dir.move_toward(adjusted_target_dir, delta / host_body.stats.turn_speed)


func get_move_dir() -> Vector2:
	return Coords.vec3_to_vec2(cur_dir)


func _start_attack_timer() -> void:
	if attack_max_seconds > 0.0:
		var seconds = randf_range(attack_min_seconds, attack_max_seconds)
		Log.debug(self, "starting attack timer", seconds)
		await get_tree().create_timer(seconds).timeout
		attack.emit.call_deferred()
		_start_attack_timer.call_deferred()


func _start_retarget_timer() -> void:
	if retarget_max_seconds > 0.0:
		var seconds = randf_range(retarget_min_seconds, retarget_max_seconds)
		Log.debug(self, "starting retarget timer", seconds)
		await get_tree().create_timer(seconds).timeout
		_retarget()
		_start_retarget_timer.call_deferred()
