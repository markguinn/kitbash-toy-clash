class_name DefaultEnemyInputSource
extends InputSource

@export var attack_min_seconds := 0.0
@export var attack_max_seconds := 0.0

@export_group("Optional Overrides")
@export var host: Node3D


func _ready() -> void:
	if not host and get_parent() is Node3D:
		host = get_parent()
	_start_attack_timer.call_deferred()


func get_move_dir() -> Vector2:
	var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
	if not player:
		return Vector2.ZERO
	# TODO: find _nearest_ player rather than just the first one
	var dir_3d := host.global_position.direction_to(player.global_position)
	return Coords.vec3_to_vec2(dir_3d)


func _start_attack_timer() -> void:
	if attack_max_seconds > 0.0:
		var seconds = randf_range(attack_min_seconds, attack_max_seconds)
		Log.debug(self, "starting attack timer", seconds)
		await get_tree().create_timer(seconds).timeout
		attack.emit.call_deferred()
		_start_attack_timer.call_deferred()
