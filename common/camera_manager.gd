class_name CameraManager
extends Camera3D

const DISTANCE_FROM_TARGET = 40.0

@export var check_cadence_sec := 0.0
@export var target_refresh_sec := 1.0
@export var y_rotation := 0.0:
	set(v):
		y_rotation = v
		_update_offset_vector()
@export var x_rotation := -50.0:
	set(v):
		x_rotation = v
		_update_offset_vector()

@export var move_speed := 50.0
@export var zoom_speed := 5.0

@export var min_distance := 40.0
@export var max_distance := 100.0

@export var edge_margin := Vector2(300.0, 150.0)
@export var edge_tolerance := 50.0

var center_point: Vector3
var target_position: Vector3
var target_zoom: float = min_distance
var next_check := 0.0
var next_target_refresh := 0.0
var targets: Array[Node3D]
var offset_vector: Vector3
var cur_zoom_speed := 0.0
var cur_move_speed := 0.0


func _ready() -> void:
	_update_offset_vector()


func _process(delta: float) -> void:
	next_target_refresh -= delta
	if next_target_refresh <= 0.0:
		targets = _find_targets()
		next_target_refresh = target_refresh_sec
		
	next_check -= delta
	if next_check <= 0.0:
		next_check = check_cadence_sec
		center_point = _find_center_point()
		var overrun := _target_overrun()
		if overrun > 1.0:
			target_zoom = min(max_distance, target_zoom + inverse_lerp(0, edge_tolerance, overrun))
		elif overrun < -1.0:
			target_zoom = max(min_distance, target_zoom - inverse_lerp(0, -edge_tolerance, overrun))
		target_position = center_point + offset_vector * DISTANCE_FROM_TARGET
		
	#var pos_diff := global_position.distance_to(target_position)
	#if pos_diff > 0.0:
		#var target_speed = remap(pos_diff, 0.0, 5.0, 0.0, move_speed)
		#cur_move_speed = move_toward(cur_move_speed, target_speed, delta * move_speed * 2.0)
	#else:
		#cur_move_speed = 0.0
	#var zoom_diff := absf(size - target_zoom)
	#if zoom_diff > 0.0:
		#cur_zoom_speed = move_toward(cur_zoom_speed, zoom_speed, delta * zoom_diff * 2.0)
	#else:
		#cur_zoom_speed = 0.0
	global_position = target_position #global_position.move_toward(target_position, delta * cur_move_speed)
	size = target_zoom # move_toward(size, target_zoom, delta * cur_zoom_speed)


func _update_offset_vector() -> void:
	rotation_degrees = Vector3(x_rotation, y_rotation, 0.0)
	offset_vector = Vector3(0, 0, 1) \
		.rotated(Vector3.RIGHT, deg_to_rad(x_rotation)) \
		.rotated(Vector3.UP, deg_to_rad(y_rotation))


func _target_overrun() -> float:
	var center_spos := unproject_position(center_point)
	var min_spos := center_spos
	var max_spos := center_spos
	for t in targets:
		var screen_pos = unproject_position(t.global_position)
		if screen_pos.x < min_spos.x:
			min_spos.x = screen_pos.x
		if screen_pos.x > max_spos.x:
			max_spos.x = screen_pos.x
		if screen_pos.y < min_spos.y:
			min_spos.y = screen_pos.y
		if screen_pos.y > max_spos.y:
			max_spos.y = screen_pos.y
	var vp_size := get_viewport().get_visible_rect().size
	var overrun: float = max(
		edge_margin.x - min_spos.x,
		edge_margin.y - min_spos.y,
		max_spos.x - vp_size.x - edge_margin.x,
		max_spos.y - vp_size.y - edge_margin.y
	)
	return overrun


func _find_center_point() -> Vector3:
	var min_p := targets[0].global_position
	var max_p := targets[0].global_position
	for t in targets:
		var p := t.global_position
		min_p.x = min(min_p.x, p.x)
		min_p.y = min(min_p.y, p.y)
		min_p.z = min(min_p.z, p.z)
		max_p.x = max(max_p.x, p.x)
		max_p.y = max(max_p.y, p.y)
		max_p.z = max(max_p.z, p.z)
	return (min_p + max_p) / 2.0


func _find_targets() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group("player"):
		if n is Node3D:
			out.append(n)
	for n in get_tree().get_nodes_in_group("camera_targets"):
		if n is Node3D:
			out.append(n)
	return out


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_cam"):
		y_rotation = snappedf(wrapf(y_rotation + 15.0, -60.0, 46.0), 15.0)
		Log.info(self, "camera rotation", y_rotation)
