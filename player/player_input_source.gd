class_name PlayerInputSource
extends InputSource

@export var keyboard_arrows: bool = true
@export var keyboard_wasd: bool = true
@export var controller_1: bool = true
@export var controller_2: bool = true


func _input(event: InputEvent) -> void:
	if (
		(keyboard_arrows and event.is_action_pressed("k1_attack")) or 
		(keyboard_wasd and event.is_action_pressed("k2_attack")) or
		(controller_1 and event.is_action_pressed("c1_attack")) or
		(controller_2 and event.is_action_pressed("c2_attack"))
	):
		attack.emit()
	if (
		(keyboard_arrows and event.is_action_pressed("k1_special")) or 
		(keyboard_wasd and event.is_action_pressed("k2_special")) or
		(controller_1 and event.is_action_pressed("c1_special")) or 
		(controller_2 and event.is_action_pressed("c2_special"))
	):
		special_attack.emit()
	if (
		(keyboard_arrows and event.is_action_pressed("k1_dash")) or 
		(keyboard_wasd and event.is_action_pressed("k2_dash")) or
		(controller_1 and event.is_action_pressed("c1_dash")) or 
		(controller_2 and event.is_action_pressed("c2_dash"))
	):
		dash.emit()

func get_move_dir() -> Vector2:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var dir: Vector2 = Vector2.ZERO
	if keyboard_arrows:
		dir = Input.get_vector("k1_left", "k1_right", "k1_up", "k1_down")
	if keyboard_wasd and dir.is_zero_approx():
		dir = Input.get_vector("k2_left", "k2_right", "k2_up", "k2_down")
	if controller_1 and dir.is_zero_approx():
		dir = Input.get_vector("c1_left", "c1_right", "c2_up", "c2_down")
	if controller_2:
		var c2_dir := Input.get_vector("c2_left", "c2_right", "c2_up", "c2_down")
		if c2_dir.length_squared() > dir.length_squared():
			dir = c2_dir
	var compensation = snappedf(cam.rotation.y, PI / 4.0)
	return dir.rotated(-compensation)
